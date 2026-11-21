#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint seeker_connect_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'seeker_connect_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Unofficial community Flutter plugin for Solana Mobile Seeker Connect (Android only; iOS is a no-op).'
  s.description      = <<-DESC
Seeker Connect is Android only. On iOS this plugin registers nothing and the Dart side reports unsupportedPlatform.
                       DESC
  s.homepage         = 'https://github.com/solanachetis/seeker-connect-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SolanaChetis' => 'https://github.com/solanachetis' }
  s.source           = { :path => '.' }
  s.source_files = 'seeker_connect_flutter/Sources/seeker_connect_flutter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'seeker_connect_flutter_privacy' => ['seeker_connect_flutter/Sources/seeker_connect_flutter/PrivacyInfo.xcprivacy']}
end
