# Uncomment the next line to define a global platform for your project
platform :macos, '10.15'

target 'Meruru' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Meruru
  pod 'VLCKit'
  pod 'Alamofire'
  pod 'thenPromise'
  pod 'SwiftyJSON'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["ONLY_ACTIVE_ARCH"] = "YES"
    end
  end
end
