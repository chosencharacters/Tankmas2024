for %%a in ("*.ogg") do ffmpeg -i "%%a" -b:a 128k -y "out\%%~na.ogg"
for %%a in ("*.mp3") do ffmpeg -i "%%a" -b:a 128k -y "out\%%~na.mp3"
pause