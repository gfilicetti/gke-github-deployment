# Accelerating ffmpeg

[ffmpeg](https://www.ffmpeg.org/) is a mature, cross-platform solution to record, convert and stream audio and video. It is a major component of many transcoding solutions, but becoming proficient at `ffmpeg` can be a challenge. Parameters can be difficult to understand and research, and complicated to understand the results.

## Using different chip architectures to accelerate ffmpeg

`ffmpeg` is designed to take advantage of different chip architectures to accelerate tasks related to video encoding and decoding.

### CPU acceleration

Most modern CPUs have [Advanced Vector Extensions](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions) (AVX) as part of their architecture, which extend the capabilities of certain x86 tasks. AVX (and its newer implementations AVX2 and AVX-512) allows you to watch a video stream with minimal impact to CPU load by accelerating the vector calculations necessary to encode or decode streaming video that use specific compression formats (e.g. [h.264](https://en.wikipedia.org/wiki/Advanced_Video_Coding) or [h.265](https://en.wikipedia.org/wiki/High_Efficiency_Video_Coding)).

### GPU acceleration

Some NVIDIA GPUs have a feature that accelerate video encoding ([NVENC](https://en.wikipedia.org/wiki/Nvidia_NVENC)) and decoding ([NVDEC](https://en.wikipedia.org/wiki/Nvidia_NVDEC)). When you [compile `ffmpeg` with nvenc libraries](https://docs.nvidia.com/video-technologies/video-codec-sdk/12.1/ffmpeg-with-nvidia-gpu/index.html), you can instruct `ffmpeg` to use these features of the GPU rather than the CPU to encode or decode video.

## Understanding ffmpeg commands

For performance and quality testing, we ran three different transcode scenarios on the same source video:

1. Transcode using CPU acceleration (with AVX).
1. Transcode using NVIDIA GPU NVENC/NVDEC acceleration.
1. Transcode using NVIDIA GPU NVENC/NVDEC acceleration but perform multiple transcodes in parallel.

The third scenario transcodes the original video into three resolutions: 720x404, 1280x718, and 1920x1077.

All scenarios perform the same tasks:

- Transcode the same source video into `.mp4` format.
- Specify target and maximum bitrates.
- Scale the original video from 4k down to 720x404 resolution.
- Encode using a 'medium' quality setting.

There are some other very specific settings at play, but to keep things simple, those are the three main transcode parameters.

## Scenario 1: CPU

This set of parameters was deemed "good enough" by WBD; they are reluctant to share their exact `ffmpeg` parameters as they consider it proprietary information. The command we used looks like this:

```console
ffmpeg \
  -i $SOURCE \
  -c:v libx264 \
  -filter:v scale="720:trunc(ow/a/2)*2" \
  -preset:v medium \
  -x264-params "keyint=120:min-keyint=120:sliced-threads=0:scenecut=0:asm=${_ASM}" \
  -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
  -c:a copy \
  -y \
  $DESTINATION.mp4
```

### Common parameters
These parameters are common across all use cases:

| flag | value | description |
| ---- | ----- | ----------- |
| `filter:v` | `scale` | Videos are scaled to 720x404 (height is forced by maintaining Aspect Ratio (AR) through calculation). |
| `preset:v` | `medium` | This is the [default preset](https://trac.ffmpeg.org/wiki/Encode/H.264#a2.Chooseapresetandtune) and the flag could be removed, however we leave it in to maintain consistency. |
| `profile:v` | `high` | Limits output to a specific H.264 profile. [Docs](https://trac.ffmpeg.org/wiki/Encode/H.264#Profile) say this flag could be removed. | 
| `b:v` | `6M` | The target (average) bit rate for the encoder to use ([docs](https://trac.ffmpeg.org/wiki/Limiting%20the%20output%20bitrate)). |
| `maxrate` | `12M` | Specifies a maximum bitrate. |
| `bufsize` | `24M` | Specifies the decoder buffer size, which determines the variability of the output bitrate. |
| `c:a` | `copy` | Copy the audio directly into the new video stream as-is. |
| `y` | | Overwrite existing files with the same name. |

### Additional parameters
These parameters are unique to the CPU-only use case:

| flag | value | description |
| ---- | ----- | ----------- |
| `c:v` | `libx264` | Utilize the libx264 codec, which is CPU-based. |
| `x264-params` | | Container for codec-specific parameters. |
| `keyint` | `120` | Specifies (in frames) the **maximum** length of a Group Of Pictures (GOP) ([more info](https://video.stackexchange.com/questions/24680/what-is-keyint-and-min-keyint-and-no-scenecut)). |
| `min-keyint` | `120` | Specifies (in frames) the **minimum** length of the GOP ([more info](https://video.stackexchange.com/questions/24680/what-is-keyint-and-min-keyint-and-no-scenecut)). Because this and the previous value are identical, the command forces the video's GOP to be of uniform length. |
| `sliced-threads` | `0` or `FALSE` | Disabled slice-based multithreading. |
| `scenecut` | `0` or `FALSE` | Disable scene detection. |
| `ASM` | `avx2` or `avx512` | Determined by `lscpu \| grep -q avx512`. |

## Scenario 2: GPU
Here we shift to hardware-accelerated transcoding, using a single NVIDIA L4 GPU. Because we have to use a different codec, some of the parameters have to change:

```console
ffmpeg \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i $SOURCE \
  -preset:v medium \
  -filter:v scale_npp="720:trunc(ow/a/2)*2" \
  -c:v h264_nvenc \
  -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
  -g 120 \
  -no-scenecut TRUE \
  -c:a copy \
  -y \
  $DESTINATION.mp4"
```

### Additional parameters
| flag | value | description |
| ---- | ----- | ----------- |
| `hwaccel` | `cuda` | Use NVIDIA GPU for decoding. |
| `hwaccel_output` | `cuda` | Use NVIDIA GPU for encoding. |
| `filter:v` | `scale_npp` | Scale video using NVENC. |
| `c:v` | `h264_nvenc` | Encode the video using the h264 codec. |
| `g` | `120` | Specifies the GOP size. We use this instead of `keyint`/`min-keyint` as those are x264-specific parameters and are incompatible with the h264_nvenc codec. |
| `no-scenecut` | `TRUE` | Disable scene detection. This flag performs the same function as the x264-param `scenecut=FALSE`. |

## Scenario 3: GPU with multiple outputs

This senario is designed to test generating multiple transcodes from the same source video in parallel. 

In this example, we encode three different resolutions, their widths being 720, 1280, and 1920. The video height is determined using a calculation that maintains the original video's aspect ratio.

```console
ffmpeg \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i $SOURCE \
  -preset:v medium \
  -map 0:0 \
    -filter:v scale_npp="720:trunc(ow/a/2)*2" \
    -c:v h264_nvenc \
    -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
    -g 120 \
    -no-scenecut TRUE \
    $DESTINATION-720.mp4" \
  -map 0:0 \
    -filter:v scale_npp="1280:trunc(ow/a/2)*2" \
    -c:v h264_nvenc \
    -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
    -g 120 \
    -no-scenecut TRUE \
    $DESTINATION-1280.mp4" \
  -map 0:0 \
    -filter:v scale_npp="1920:trunc(ow/a/2)*2" \
    -c:v h264_nvenc \
    -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
    -g 120 \
    -no-scenecut TRUE \
    $DESTINATION-1920.mp4" \
  -c:a copy \
  -y
```

As this command is based on the first GPU command, there are no additional parameters. The structure of this command, however, is how `ffmpeg` deals with multiple inputs or outputs using the `-map` flag. Each use of this flag will invoke a separate task (in parallel with all other jobs), each with unique settings and filename.

There is a way to specify common parameters once using `-filter_complex`, but I have yet to figure that out.

## Performance comparisons

Rudimentary testing shows GPU performance to be almost 3x the speed of the same command run on CPU-only. Encoding multiple resolutions only adds a few seconds total, creating massive value to the added cost of the GPU. In the GPU (multi) scenario, we are encoding THREE videos in parallel.

| | CPU | GPU | GPU (multi) |
| -- | ---- | ----- | ----------- |
| duration (s) | 489.84 | 176.54 | 180.28 |
| multiplier | 1.000 | 2.775 | 2.717 |
| max enc | 0% | 5% | 48% |
| max dec | 0% | 25% | 25% |

`max enc` and `max dec` are the maximum observed use of NVENC and NVDEC (respectively), as reported by `nvidia-smi dmon -s pucvmet`.

## Quality comparisons

Unfortunately, the encoding quality between GPU and CPU do not provide the same results, despite using nearly identical encoding parameters. You can observe this in frames with very fine details such as a field of grass.
Note the image on the left (transcoded using GPU) is much noisier than the one on the right (transcoded using CPU):

![GPU vs CPU](docs/img/bbb-wide-cpu-gpu.jpg)

If we zoom in on a different frame, you can see the GPU-accelerated transcode is much noisier than the image transcoded via CPU:

<img src="docs/img/bbb-med-gpu.jpg" width="300"> <img src="docs/img/bbb-med-cpu.jpg" width="300">

We need to determine how to increase the quality and filtering of hardware-accelerated encoding via `ffmpeg` to match the quality of the base transcoded video.

Zooming in even closer makes the issue even more apparent:

<img src="docs/img/bbb-close-gpu.jpg" width="500"> 
<img src="docs/img/bbb-close-cpu.jpg" width="500">

Adrian Graham, 2024-09-05