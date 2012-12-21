class S3UploadViewController < UIViewController
  ACCESS_KEY_ID = "your access key ID"
  SECRET_KEY    = "your securet key"

  def viewDidLoad
    super

    self.navigationItem.title = "S3 Uploader in Motion"
    self.view.backgroundColor = UIColor.whiteColor

    @s3 = AmazonS3Client.alloc.initWithAccessKey(ACCESS_KEY_ID, withSecretKey: SECRET_KEY)
    response = @s3.createBucket(S3CreateBucketRequest.alloc.initWithName("s3uploader-motion-sample"))
    if (response.error != nil)
      alert(response.error)
    end

    UIButton.buttonWithType(UIButtonTypeRoundedRect).tap do |button|
      button.setTitle("Upload Photo", forState:UIControlStateNormal)
      button.frame = [[10, 100], [view.frame.size.width - 20, 40]]
      button.when(UIControlEventTouchUpInside) do
        showImagePicker
      end
      self.view.addSubview(button)
    end

    UIButton.buttonWithType(UIButtonTypeRoundedRect).tap do |button|
      button.setTitle "Open Photo", forState:UIControlStateNormal
      button.frame = [[10, 150], [view.frame.size.width - 20, 40]]
      button.when(UIControlEventTouchUpInside) do
        showInBrowser
      end
      self.view.addSubview(button)
    end
  end

  def showImagePicker
    UIImagePickerController.new.tap do |picker|
      picker.delegate = self
      self.presentModalViewController(picker, animated:true)
    end
  end

  def imagePickerController(picker, didFinishPickingMediaWithInfo: info)
    image = info.objectForKey(UIImagePickerControllerOriginalImage)
    processDispatchUpload(UIImageJPEGRepresentation(image, 1.0))
    picker.dismissModalViewControllerAnimated(true)
  end

  def processDispatchUpload(imageData)
    UIApplication.sharedApplication.setNetworkActivityIndicatorVisible(true)
    Dispatch::Queue.concurrent.async do
      req = S3PutObjectRequest.alloc.initWithKey("sample.jpg", inBucket: "s3uploader-motion-sample").tap do |r|
        r.contentType = "image/jpeg"
        r.data = imageData
      end

      response = @s3.putObject(req)

      Dispatch::Queue.main.sync do
        if (response.error != nil)
          alert(response.error)
        end
        UIApplication.sharedApplication.setNetworkActivityIndicatorVisible(false)
      end
    end
  end

  def showInBrowser
    Dispatch::Queue.concurrent.async do
      request = S3GetPreSignedURLRequest.new.tap do |r|
        r.key     = "sample.jpg"
        r.bucket  = "s3uploader-motion-sample"
        r.expires = NSDate.dateWithTimeIntervalSinceNow(3600)
        r.responseHeaderOverrides =  S3ResponseHeaderOverrides.new.tap { |o| o.contentType = "image/jpeg" }
      end

      err = Pointer.new(:object)
      url = @s3.getPreSignedURL(request, error:err)

      Dispatch::Queue.main.sync do
        if (url == nil)
          if (error[0] != nil)
            alert(error[0])
          end
        else
          App.open_url(url)
        end
      end
    end
  end

  def alert(msg)
    UIAlertView.new.tap do |v|
      v.message = msg
      v.show
    end
  end
end
