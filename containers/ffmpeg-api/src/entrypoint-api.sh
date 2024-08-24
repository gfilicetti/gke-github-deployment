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

touch "${_DST}"/"${_FILENAME}-hd.mp4"

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

_MEDIAINFO_DST_START="$(date "+%F %T,%3N")" >> "${_STATS}"
mediainfo "${_DST}"/"${_FILENAME}-hd.mp4" >> "${_STATS}"
_MEDIAINFO_DST_END="$(date "+%F %T,%3N")" >> "${_STATS}"

exectime "${_MEDIAINFO_SRC_START}" "${_MEDIAINFO_SRC_END}" "original Mediainfo" >> "${_STATS}"
exectime "${_FFMPEG_START}" "${_FFMPEG_END}" "FFMpeg transcoding" >>"${_STATS}"
exectime "${_MEDIAINFO_DST_START}" "${_MEDIAINFO_DST_END}" "transcoded Mediainfo" >> "${_STATS}"
_VERYEND="$(date "+%F %T,%3N")" >> "${_STATS}"

exectime "${_VERYSTART}" "${_VERYEND}" "the entire process" >> "${_STATS}"
echo "### Ending at: $(date "+%F %T,%3N")"