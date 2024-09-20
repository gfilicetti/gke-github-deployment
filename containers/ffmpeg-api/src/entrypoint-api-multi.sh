#!/bin/bash

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# NOTE:
#   Input variables required:
#		$MEDIA = base name of input media file
#		$TRANSCODE_MODE = specify whether to encode with CPU or GPU.
#			0 = CPU
#			1 = GPU
#			2 = GPU w/multiple outputs to test parallel encoding

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

###Generating MEDIA based in a list, file.list, 
echo "### Transcoding ${MEDIA}"

_SRC=/input
_DST="/output"

_EXTENSION="${MEDIA##*.}"
_BASENAME="$(basename "${MEDIA}")"
_FILENAME="${_BASENAME%.*}_$(date "+%F-%H-%M-%S")"

_STATS="${_DST}"/"${_FILENAME}_stats.txt"

_MEDIAINFO_SRC_START="$(date "+%F %T,%3N")" >> "${_STATS}"
mediainfo "${_SRC}"/"${MEDIA}" >> "${_STATS}"
_MEDIAINFO_SRC_END="$(date "+%F %T,%3N")" >> "${_STATS}"

lscpu | grep -q avx512
[[ $? = 0 ]] && _ASM="avx512" || _ASM="avx2"


_FFMPEG_START="$(date "+%F %T,%3N")"
case $TRANSCODE_MODE in
	# Transcode using GPU.
	1)
		touch "${_DST}"/"${_FILENAME}-hd.mp4"
		ffmpeg \
			-hwaccel cuda \
			-hwaccel_output_format cuda \
			-i "${_SRC}"/"${MEDIA}" \
			-preset:v medium \
			-filter:v scale_npp="720:trunc(ow/a/2)*2" \
			-c:v h264_nvenc \
			-profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
			-g 120 \
			-no-scenecut TRUE \
			-c:a copy \
			-y \
			"${_DST}"/"${_FILENAME}-hd.mp4"
		;;
	# Transcode using GPU, run in parallel.
	2)
		touch "${_DST}"/"${_FILENAME}-720.mp4"
		touch "${_DST}"/"${_FILENAME}-1280.mp4"
		touch "${_DST}"/"${_FILENAME}-1920.mp4"
		ffmpeg \
			-hwaccel cuda \
			-hwaccel_output_format cuda \
			-i "${_SRC}"/"${MEDIA}" \
			-preset:v medium \
			-map 0:0 \
				-filter:v scale_npp="720:trunc(ow/a/2)*2" \
				-c:v h264_nvenc \
				-profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
				-g 120 \
				-no-scenecut TRUE \
				"${_DST}"/"${_FILENAME}-720.mp4" \
			-map 0:0 \
				-filter:v scale_npp="1280:trunc(ow/a/2)*2" \
				-c:v h264_nvenc \
				-profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
				-g 120 \
				-no-scenecut TRUE \
				"${_DST}"/"${_FILENAME}-1280.mp4" \
			-map 0:0 \
				-filter:v scale_npp="1920:trunc(ow/a/2)*2" \
				-c:v h264_nvenc \
				-profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
				-g 120 \
				-no-scenecut TRUE \
				"${_DST}"/"${_FILENAME}-1920.mp4" \
			-c:a copy \
			-y
		;;
	# transcode using CPU.
	*)
		touch "${_DST}"/"${_FILENAME}-hd.mp4"
		ffmpeg \
			-i "${_SRC}"/"${MEDIA}" \
			-c:v libx264 \
			-filter:v scale="720:trunc(ow/a/2)*2" \
			-preset:v medium \
			-x264-params "keyint=120:min-keyint=120:sliced-threads=0:scenecut=0:asm=${_ASM}" \
			-profile:v high -b:v 6M -maxrate 12M -bufsize 24M \
			-c:a copy \
			-y \
			"${_DST}"/"${_FILENAME}-hd.mp4"
		;;
esac # end case $TRANSCODE_MODE
_FFMPEG_END="$(date "+%F %T,%3N")"

_MEDIAINFO_DST_START="$(date "+%F %T,%3N")" >> "${_STATS}"
mediainfo "${_DST}"/"${_FILENAME}-hd.mp4" >> "${_STATS}"
_MEDIAINFO_DST_END="$(date "+%F %T,%3N")" >> "${_STATS}"

exectime "${_MEDIAINFO_SRC_START}" "${_MEDIAINFO_SRC_END}" "original Mediainfo" >> "${_STATS}"
exectime "${_FFMPEG_START}" "${_FFMPEG_END}" "FFMpeg transcoding" >>"${_STATS}"
exectime "${_MEDIAINFO_DST_START}" "${_MEDIAINFO_DST_END}" "transcoded Mediainfo" >> "${_STATS}"
_VERYEND="$(date "+%F %T,%3N")" >> "${_STATS}"

exectime "${_VERYSTART}" "${_VERYEND}" "the entire process" >> "${_STATS}"
echo "### Ending at: $(date "+%F %T,%3N")"
