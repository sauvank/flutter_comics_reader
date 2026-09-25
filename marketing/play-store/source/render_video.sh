#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MARKETING_DIR="$ROOT_DIR/marketing/play-store"
OUTPUT_DIR="$MARKETING_DIR/exports/video"
FONT_FILE="$MARKETING_DIR/source/fonts/Manrope.ttf"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

WIDTH=1920
HEIGHT=1080
FPS=30
SCENE_DURATION=4.5
TRANSITION_DURATION=0.6

make_phone_scene() {
  local output="$1"
  local image="$2"
  local section="$3"
  local title="$4"
  local subtitle="$5"
  local accent="$6"

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=0x17112e:s=${WIDTH}x${HEIGHT}:r=${FPS}:d=${SCENE_DURATION}" \
    -loop 1 -i "$image" \
    -filter_complex "
      [1:v]scale=540:864,format=rgba,
        fade=t=in:st=0:d=0.45:alpha=1[screen];
      [0:v]drawbox=x=0:y=0:w=1920:h=1080:color=0x17112e:t=fill,
        drawbox=x=0:y=0:w=18:h=1080:color=${accent}:t=fill,
        drawbox=x=1175:y=65:w=650:h=950:color=0x0b0817@0.72:t=fill,
        drawbox=x=1232:y=98:w=576:h=884:color=${accent}@0.18:t=fill,
        drawtext=fontfile=${FONT_FILE}:text='ComicStream':x=105:y=92:fontsize=30:fontcolor=0x54d7e4,
        drawtext=fontfile=${FONT_FILE}:text='${section}':x=105:y=190:fontsize=25:fontcolor=white@0.62,
        drawtext=fontfile=${FONT_FILE}:text='${title}':x=105:y=278:fontsize=72:fontcolor=white,
        drawtext=fontfile=${FONT_FILE}:text='${subtitle}':x=105:y=400:fontsize=36:fontcolor=white@0.76,
        drawbox=x=105:y=520:w=155:h=7:color=${accent}:t=fill,
        drawtext=fontfile=${FONT_FILE}:text='Vos fichiers. Votre bibliothèque.':x=105:y=850:fontsize=27:fontcolor=white@0.50[base];
      [base][screen]overlay=x='1248+70*(1-min(t/0.7\,1))':y=108:eval=frame:shortest=1,
        vignette=PI/5,format=yuv420p[out]
    " \
    -map "[out]" -t "$SCENE_DURATION" -r "$FPS" \
    -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$output"
}

make_intro() {
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=0x17112e:s=${WIDTH}x${HEIGHT}:r=${FPS}:d=${SCENE_DURATION}" \
    -loop 1 -i "$ROOT_DIR/assets/icon/playstore_icon_512.png" \
    -filter_complex "
      [1:v]scale=510:510,format=rgba,fade=t=in:st=0.15:d=0.6:alpha=1[icon];
      [0:v]drawbox=x=0:y=0:w=1920:h=1080:color=0x17112e:t=fill,
        drawbox=x=0:y=0:w=1920:h=16:color=0x54d7e4:t=fill,
        drawbox=x=1160:y=70:w=650:h=940:color=0x403265@0.45:t=fill,
        drawtext=fontfile=${FONT_FILE}:text='ComicStream':x=120:y=285:fontsize=105:fontcolor=white,
        drawtext=fontfile=${FONT_FILE}:text='Vos BD, partout avec vous.':x=125:y=430:fontsize=49:fontcolor=0x54d7e4,
        drawtext=fontfile=${FONT_FILE}:text='Lisez vos collections sur téléphone et tablette.':x=125:y=535:fontsize=32:fontcolor=white@0.70,
        drawbox=x=125:y=650:w=210:h=8:color=0xb66cf3:t=fill[base];
      [base][icon]overlay=x='1230+80*(1-min(t/0.8\,1))':y=285:eval=frame:shortest=1,
        vignette=PI/5,format=yuv420p[out]
    " \
    -map "[out]" -t "$SCENE_DURATION" -r "$FPS" \
    -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$TMP_DIR/scene-01.mp4"
}

make_dual_scene() {
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=0x17112e:s=${WIDTH}x${HEIGHT}:r=${FPS}:d=${SCENE_DURATION}" \
    -loop 1 -i "$MARKETING_DIR/captures/phone/01-library.png" \
    -loop 1 -i "$MARKETING_DIR/captures/tablet/02-reader.png" \
    -filter_complex "
      [1:v]scale=385:616,format=rgba,fade=t=in:st=0:d=0.45:alpha=1[phone];
      [2:v]scale=520:832,format=rgba,fade=t=in:st=0.18:d=0.55:alpha=1[tablet];
      [0:v]drawbox=x=0:y=0:w=1920:h=1080:color=0x17112e:t=fill,
        drawbox=x=0:y=0:w=18:h=1080:color=0x54d7e4:t=fill,
        drawtext=fontfile=${FONT_FILE}:text='MULTI-APPAREILS':x=100:y=175:fontsize=25:fontcolor=white@0.62,
        drawtext=fontfile=${FONT_FILE}:text='Continuez sur':x=100:y=275:fontsize=70:fontcolor=white,
        drawtext=fontfile=${FONT_FILE}:text='chaque écran.':x=100:y=365:fontsize=70:fontcolor=white,
        drawtext=fontfile=${FONT_FILE}:text='Téléphone et tablette, même progression.':x=100:y=510:fontsize=34:fontcolor=0x54d7e4,
        drawtext=fontfile=${FONT_FILE}:text='Vous choisissez la position à conserver.':x=100:y=570:fontsize=28:fontcolor=white@0.66,
        drawbox=x=100:y=680:w=175:h=7:color=0xb66cf3:t=fill[base];
      [base][phone]overlay=x='1065+60*(1-min(t/0.7\,1))':y=320:eval=frame:shortest=1[first];
      [first][tablet]overlay=x='1370+70*(1-min(t/0.8\,1))':y=125:eval=frame:shortest=1,
        vignette=PI/5,format=yuv420p[out]
    " \
    -map "[out]" -t "$SCENE_DURATION" -r "$FPS" \
    -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$TMP_DIR/scene-06.mp4"
}

make_outro() {
  ffmpeg -hide_banner -loglevel error -y \
    -loop 1 -i "$MARKETING_DIR/exports/feature-graphic.jpg" \
    -filter_complex "
      [0:v]scale=1920:-2,pad=1920:1080:0:(oh-ih)/2:color=0x17112e,
        drawbox=x=0:y=0:w=1920:h=16:color=0x54d7e4:t=fill,
        drawbox=x=0:y=948:w=1920:h=132:color=0x0d091a@0.72:t=fill,
        drawtext=fontfile=${FONT_FILE}:text='Disponible sur Google Play':x=(w-text_w)/2:y=985:fontsize=34:fontcolor=white@0.88,
        vignette=PI/5,format=yuv420p[out]
    " \
    -map "[out]" -t "$SCENE_DURATION" -r "$FPS" \
    -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$TMP_DIR/scene-07.mp4"
}

make_intro
make_phone_scene "$TMP_DIR/scene-02.mp4" \
  "$MARKETING_DIR/captures/phone/01-library.png" \
  "BIBLIOTHÈQUE" "Toute votre bibliothèque." \
  "Séries, favoris et progression." "0x54d7e4"
make_phone_scene "$TMP_DIR/scene-03.mp4" \
  "$MARKETING_DIR/captures/phone/02-reader.png" \
  "LECTURE" "Une lecture à votre rythme." \
  "Page, manga ou webtoon." "0xb66cf3"
make_phone_scene "$TMP_DIR/scene-04.mp4" \
  "$MARKETING_DIR/captures/phone/04-settings.png" \
  "CONFORT" "Vos réglages, votre lecture." \
  "Sens, ajustement et fond." "0xf0a96b"
make_phone_scene "$TMP_DIR/scene-05.mp4" \
  "$MARKETING_DIR/captures/phone/05-servers.png" \
  "COLLECTIONS" "Connectez vos bibliothèques." \
  "WebDAV, HTTP et FTP." "0x54d7e4"
make_dual_scene
make_outro

ffmpeg -hide_banner -loglevel error -y \
  -i "$TMP_DIR/scene-01.mp4" \
  -i "$TMP_DIR/scene-02.mp4" \
  -i "$TMP_DIR/scene-03.mp4" \
  -i "$TMP_DIR/scene-04.mp4" \
  -i "$TMP_DIR/scene-05.mp4" \
  -i "$TMP_DIR/scene-06.mp4" \
  -i "$TMP_DIR/scene-07.mp4" \
  -f lavfi -t 27.9 -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
  -filter_complex "
    [0:v][1:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=3.9[v1];
    [v1][2:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=7.8[v2];
    [v2][3:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=11.7[v3];
    [v3][4:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=15.6[v4];
    [v4][5:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=19.5[v5];
    [v5][6:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=23.4,
      format=yuv420p[video]
  " \
  -map "[video]" -map 7:a -t 27.9 -r "$FPS" \
  -c:v libx264 -preset medium -crf 18 -profile:v high -level 4.1 \
  -c:a aac -b:a 128k -movflags +faststart \
  "$OUTPUT_DIR/comicstream-google-play-fr.mp4"

ffmpeg -hide_banner -loglevel error -y \
  -ss 1.8 -i "$OUTPUT_DIR/comicstream-google-play-fr.mp4" \
  -frames:v 1 -q:v 2 "$OUTPUT_DIR/youtube-thumbnail.jpg"

echo "Vidéo créée : $OUTPUT_DIR/comicstream-google-play-fr.mp4"
echo "Miniature créée : $OUTPUT_DIR/youtube-thumbnail.jpg"
