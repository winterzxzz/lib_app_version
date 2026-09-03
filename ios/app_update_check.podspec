#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint app_update_check.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'app_update_check'
  s.version          = '1.0.0'
  s.summary          = 'Store version check, TestFlight detection and update dialog for Flutter.'
  s.description      = <<-DESC
Check whether a newer version of the app is on the App Store / Play Store,
detect TestFlight builds and open the store listing.
                       DESC
  s.homepage         = 'https://github.com/winterzxzz/app_update_check'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'winterzxzz' => 'athenna.2k3@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'app_update_check/Sources/app_update_check/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'app_update_check_privacy' => ['app_update_check/Sources/app_update_check/PrivacyInfo.xcprivacy']}
end
