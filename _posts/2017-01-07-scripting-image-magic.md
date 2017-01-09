---
layout: post
title:  "Scripting with ImageMagick. Mass resize and add watermark to photos."
date:   2017-01-07 10:00:00
categories: article
tags: [linux, software]
---

ImageMagick mass resize
-----------------------

I take a lot of photos and standard result is 20MP image file sizing 4-10MB.
It's not big, but there are a lot of reasons you don't want to throw original
size photos on the web.

As a GNU/Linux long time user I resolve my problems by creating scripts
and using already available tools.

I've created simple `bash` script to iterate by images, check if it wasn't already
resized and resize them to .

```bash
mkdir small
for file in $(find . -iname '*.jpg'); do
  if [ -f small/${file} ];
  then
    echo "File small/${file} exists."
  else
    echo -n Converting ${file}...
    convert -resize 2048\> "$file" "small/$file"
    echo done
  fi

done
```

You can find more information about [CLI processing](https://www.imagemagick.org/script/command-line-processing.php),
[resize](http://www.imagemagick.org/Usage/resize/) and
[geometry](https://www.imagemagick.org/Magick++/Geometry.html).

TODO: I need to fix resize size for vertical images.

Add watermark
-------------

Until today I rarely added any watermarks or information about author
into images.

After some big changes in my second blog I can put my photos as a file. I don't
need to use external services like [500px](https://500px.com) or SmugMug.
I thought about property issues and content stealing.

There is problem and solution could by only similar - writing another script.

If you want to add watermark using ImageMagick you can do it using

```bash
composite -dissolve 50% -gravity south WATERMARK.png INPUT.jpg OUTPUT.jpg
```

Source: [ImageMagick forum post](http://www.imagemagick.org/discourse-server/viewtopic.php?t=19177#p74840)

Mix resize and add watermark
----------------------------

You can pipe ImageMagick commands with `miff:-` as in example below

```bash
convert -resize 2048\> "INPUT_ORIGINAL_SIZE.jpg" miff:- | composite -quality 80 -dissolve 50% -gravity south WATERMARK.png  miff:- OUTPUT_RESIZED.jpg
```

I assumed JPEG quality as 80.

Mass resize and add watermark
-----------------------------

Mixing all above knowledge I've upgraded my resize script to add watermark.


```bash
mkdir small
for file in $(find . -iname '*.jpg'); do
  if [ -f small/${file} ];
  then
   echo "File small/${file} exists."
  else
    echo -n Converting ${file}...
    convert -resize 2048\> "$file" miff:- | composite -quality 80 -dissolve 50% -gravity south ~/Obrazy/watermark.png  miff:- "small/$file"
    echo done
  fi

done
```

It's a bit slower now, keep that in mind.

Protip: You can keep watermak file in somewhere else and use absolute path.
