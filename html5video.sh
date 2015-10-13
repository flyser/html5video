#!/bin/sh

if ! [[ 1 -eq 1 ]] 2>/dev/null ; then
  alias [[=[
fi

set -e

if [[ "x$1" == "x" ]]; then
  echo "Usage:"
  echo "  $0 inputfile"
  exit 1
fi

if [[ ! -e "$1" ]]; then
  echo "Input file does not exist"
  exit 1
fi

if [[ -e "poster.jpeg" ]]; then
  echo -e "\033[1;31;40mWon't regenerate \"poster.jpeg\".\033[m"
else
  TEMPFILE="$(mktemp -u "poster-XXXXXXXXX.png")"
  MAXSIZE="250" # kilobyte
  ffmpeg -i "$1" -vframes 1 -map 0:v:0 "$TEMPFILE" || exit 1

  # Dumbest "algorithm" on the planet, but hey ...
  for i in "2073600 100 85" "921600 100 50" "230400 100 10" ; do
    pixelnum="$(echo "$i" | cut -d " " -f 1)"
    maxquality="$(echo "$i" | cut -d " " -f 2)"
    minquality="$(echo "$i" | cut -d " " -f 3)"
    for quality in $(seq $maxquality -1 $minquality) ; do
      convert -resize ${pixelnum}@\> -quality $quality "$TEMPFILE" "poster.jpeg"
      [[ $(du -k "poster.jpeg" | cut -f 1) -le $MAXSIZE ]] && break
    done
    [[ $(du -k "poster.jpeg" | cut -f 1) -le $MAXSIZE ]] && break
  done
  echo -e "poster.jpeg: size=$pixelnum\tquality=$quality\tfilesize=$(du -k "poster.jpeg" | cut -f 1)"
  rm "$TEMPFILE"
fi

# MP4 (H264, AAC) loop
for i in "144p 256 144 64 baseline 192" "240p 426 240 96 baseline 384" "360p 640 360 128 baseline 768" "480p 854 480 128 main 1536" "720p 1280 720 192 main 2560" "1080p 1920 1080 192 high 3548" ; do # "original 1920 1080 256 high crf17"
  name="$(echo "$i" | cut -d " " -f 1)"
  width="$(echo "$i" | cut -d " " -f 2)"
  height="$(echo "$i" | cut -d " " -f 3)"
  audio_bitrate="$(echo "$i" | cut -d " " -f 4)"
  video_profile="$(echo "$i" | cut -d " " -f 5)"
  video_bitrate="$(echo "$i" | cut -d " " -f 6)"

  filename="video_${name}.mp4"
  
  if [[ -e "${filename}" ]]; then
    echo -e "\033[1;31;40mWon't regenerate \"${filename}\".\033[m"
  else
    if [[ "${video_bitrate:0:3}" == "crf" ]]; then
      ffmpeg     -i "$1" -threads 0 -movflags +faststart -c:v libx264 -pix_fmt yuv420p -profile:v "$video_profile" -preset veryslow -crf "${video_bitrate:3}" -c:a libfdk_aac -b:a "${audio_bitrate}k" -vf "scale=trunc(${width}/2)*2:trunc(${height}/2)*2" "${filename}" || exit 1
    else
      rm -f ffmpeg2pass*
      ffmpeg -y  -i "$1" -threads 0 -c:v libx264 -pix_fmt yuv420p -profile:v "$video_profile" -preset veryslow -b:v "${video_bitrate}k" -pass 1 -c:a libfdk_aac -b:a "${audio_bitrate}k" -vf "scale=trunc(${width}/2)*2:trunc(${height}/2)*2" -f mp4  /dev/null || exit 1
      ffmpeg     -i "$1" -threads 0 -movflags +faststart -c:v libx264 -pix_fmt yuv420p -profile:v "$video_profile" -preset veryslow -b:v "${video_bitrate}k" -pass 2 -c:a libfdk_aac -b:a "${audio_bitrate}k" -vf "scale=trunc(${width}/2)*2:trunc(${height}/2)*2" "${filename}" || exit 1
      rm -f ffmpeg2pass*
    fi
  fi
done

# WebM loop
for i in "144p 256 144 64 192" "240p 426 240 96 384" "360p 640 360 128 512" "480p 854 480 128 1280" "720p 1280 720 192 2048" "1080p 1920 1080 192 2560" ; do # "original 1920 1080 256 30720"
  name="$(echo "$i" | cut -d " " -f 1)"
  width="$(echo "$i" | cut -d " " -f 2)"
  height="$(echo "$i" | cut -d " " -f 3)"
  audio_bitrate="$(echo "$i" | cut -d " " -f 4)"
  video_bitrate="$(echo "$i" | cut -d " " -f 5)"

  filename="video_${name}.webm"

  if [[ -e "${filename}" ]]; then
    echo -e "\033[1;31;40mWon't regenerate \"${filename}\".\033[m"
  else
    ## VP8
    # ffmpeg -i "$1" -threads 0 -c:v libvpx -c:a libvorbis -b:a "${audio_bitrate}k" -pix_fmt yuv420p -quality good -b:v "${video_bitrate}k" -crf 4 -vf "scale=trunc(${width}/2)*2:trunc(${height}/2)*2" "${filename}" || exit 1
    ## VP9
    ffmpeg -i "$1" -threads 0 -c:v vp9 -c:a libopus -b:a "${audio_bitrate}k" -vbr on -compression_level 10 -pix_fmt yuv420p -quality good -b:v "${video_bitrate}k" -crf 4 -vf "scale=trunc(${width}/2)*2:trunc(${height}/2)*2" -strict -2 "${filename}" || exit 1
  fi
done

if [[ -e "index.html" ]]; then
  echo -e "\033[1;31;40mWon't regenerate \"index.html\".\033[m"
else
  cat "$(dirname "$0")"/index.html.template | sed "s#%%ORIGINAL_FILENAME%%#${1}#g" > index.html
fi
