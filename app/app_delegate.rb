class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds).tap do |w|
      w.rootViewController =
        UINavigationController.alloc.initWithRootViewController(S3UploadViewController.new)
      w.makeKeyAndVisible
    end
  end
end
