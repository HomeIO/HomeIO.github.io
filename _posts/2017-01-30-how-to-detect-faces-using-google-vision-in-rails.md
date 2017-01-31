---
layout: post
title:  "How to start using Google Vision in Rails"
date:   2017-01-30 17:00:00
categories: article
tags: [web, software]
---


I won't explain how to use [carrierwave](https://github.com/carrierwaveuploader/carrierwave)
and upload images to Rails here. Lets assume this part is ready and well understand.

Create Google API account
-------------------------

Whole process is not very easy nor obvious. I'll explain what I remember without
telling all the details to let you grow some hate towards Google :)

1. You must [create account](https://cloud.google.com/vision/). Keep in mind you
need to attach credit card to end signing process.

2. Create new project.

3. Generate and download JSON key file. The file you downloaded is base64
   encoded JSON.

   Funny that you must decode it by yourself and Google
   doesn't tell you about it, isn't it?

   ```bash
   cat instaupload-ad4695a0c2d0.txt | base64 --decode > instaupload-ad4695a0c2d0.json
   ```

Rails code
----------

I found existing Ruby [sample code](https://github.com/GoogleCloudPlatform/ruby-docs-samples/blob/master/vision/detect_faces.rb)
how to use Google gem.

0. Add official Google API gem.

   ```ruby
   gem 'google-cloud'
   ```

1. I prefer to use `service` for that kind of operation, for example:
   put code inside class in `app/services/google_faces.rb`.

2. Sign in into Google API:   

   ```ruby
   vision = Google::Cloud::Vision.new(
     project: "instaupload",
     keyfile: "instaupload-ad4695a0c2d0.json"
    )
   ```

3. Upload image to Google API:

   ```ruby
   # photo is an instance of Photo model which has attached `image` as `carrierwave` `ImageUploader`
   image = vision.image photo.image.path
   faces = image.faces
   ```

4. Wait for results and iterate:

   ```ruby
   faces.each do |face|
   Rails.logger.debug "Face bounds:"
   face.bounds.face.each do |vector|
     Rails.logger.debug "(#{vector.x}, #{vector.y})"
   end

   x1 = face.bounds.face[0].x.to_i
   y1 = face.bounds.face[0].y.to_i
   x2 = face.bounds.face[2].x.to_i
   y2 = face.bounds.face[2].y.to_i
   ```
