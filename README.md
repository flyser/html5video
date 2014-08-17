A small script that encodes a video in multiple resolutions for
html5 browsers and generates a fullscreen video player index.html.

## Dependencies ##

 * Recent ffmpeg (I used version 2.2.5)
 * x264
 * libvpx (at least version 1.3.0, 1.4/git version recommended)
 * libfdk_aac
 * opus

## Setup ##

1. `git clone https://github.com/flyser/html5video`
2. Move the flowplayer directory to the root of your webserver
3. `cd /your_webroot/flowplayer`
4. `./download.sh` # This downloads the latest flowplayer version, rerun this to update.
5. `cd /your_webroot/some/empty/directory`
6. `cp yourvideofile .` # Not strictly neccessary, but highly recommended
7. `/gitrepo/html5video.sh yourvideofile`
8. Enjoy

Repeat steps 5-8 for every new video.

Also make sure your webserver has the following mimetypes configured:

	AddType video/ogg .ogv
	AddType video/mp4 .mp4
	AddType video/webm .webm

And make sure mp4 and webm files are not gzip compressed by your webserver:

	SetEnvIfNoCase Request_URI \.(mp4|webm)$ no-gzip dont-vary

## Known Issues ##

* Older browser versions are intentionally not well supported. Tested with Firefox 30 (android, desktop), Chrome 36 (android), IE11 (Windows 8.1).
* The script does not try very hard to catch all special cases and possible errors

