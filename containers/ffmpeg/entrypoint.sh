#!/bin/bash

function exectime {
	_START="$1"
	_END="$2"
	_NAME="$3"
	start_timestamp=$(date -d "${_START}" +%s%3N)
	end_timestamp=$(date -d "${_END}" +%s%3N)
	time_difference=$((end_timestamp - start_timestamp))
	seconds=$((time_difference / 1000))
	milliseconds=$((time_difference % 1000))
	echo "### Execution of ${_NAME} took -> ${seconds},${milliseconds}"
}

_VERYSTART="$(date "+%F %T,%3N")"
echo "### Start time: ${_VERYSTART}"
echo "### Transcoding ${MEDIA}"
echo "### Output Path ${OUTPUT_PATH}"

_SRC=/input
_DST="/output/${OUTPUT_PATH}"

_EXTENSION="${MEDIA##*.}"
_BASENAME="$(basename "${MEDIA}")"
_FILENAME="${_BASENAME%.*}"

_MEDIAINFO_SRC_START="$(date "+%F %T,%3N")"
mediainfo "${_SRC}"/"${MEDIA}"
_MEDIAINFO_SRC_END="$(date "+%F %T,%3N")"

echo "### Creating Output Path ${_DST}"
mkdir -p _DST

lscpu | grep -q avx512
[[ $? = 0 ]] && _ASM="avx512" || _ASM="avx2"

_FFMPEG_START="$(date "+%F %T,%3N")"
ffmpeg \
	-i "${_SRC}"/"${MEDIA}" \
	-c:v libx264 \
	-filter:v scale="720:trunc(ow/a/2)*2" \
	-preset:v medium \
	-x264-params "keyint=120:min-keyint=120:sliced-threads=0:scenecut=0:asm=${_ASM}" \
	-tune psnr -profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
	-c:a copy \
	-y \
	"${_DST}"/"${_FILENAME}-hd.mp4"
_FFMPEG_END="$(date "+%F %T,%3N")"

_MEDIAINFO_DST_START="$(date "+%F %T,%3N")"
mediainfo "${_DST}"/"${_FILENAME}-hd.mp4"
_MEDIAINFO_DST_END="$(date "+%F %T,%3N")"

exectime "${_MEDIAINFO_SRC_START}" "${_MEDIAINFO_SRC_END}" "original Mediainfo"
exectime "${_FFMPEG_START}" "${_FFMPEG_END}" "FFMpeg transcoding"
exectime "${_MEDIAINFO_DST_START}" "${_MEDIAINFO_DST_END}" "transcoded Mediainfo"
_VERYEND="$(date "+%F %T,%3N")"

exectime "${_VERYSTART}" "${_VERYEND}" "the entire process"
echo "### Ending at: $(date "+%F %T,%3N")"