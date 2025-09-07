
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'BroadcastUpload' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for BroadcastUpload
  
  pod 'HaishinKit', '~> 1.1.5'
  
  
  
end

target 'BroadcastUploadSetupUI' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for BroadcastUploadSetupUI
  
end

target 'ScreenRecorder' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for ScreenRecorder
  pod 'FacebookShare'
  pod 'SnapSDK', '2.4.0', :subspecs => ['SCSDKCreativeKit']
  pod 'SDWebImage', '~> 5.0'
  pod 'Firebase/Analytics'
  pod 'Google-Mobile-Ads-SDK'
  pod 'RevenueCat'
  pod 'SlideShowMaker'
  
  
end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end
