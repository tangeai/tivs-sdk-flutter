#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rapid_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rapid_kit'
  s.version          = '1.8.0-alpha.12'
  s.summary          = 'Real-time Audio-visual Platform for IoT Devices by tange-ai'
  s.description      = <<-DESC
Real-time Audio-visual Platform for IoT Devices by tange-ai
                       DESC
  s.homepage         = 'https://tange.ai/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'fengjun' => 'fengjun.dev@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'Frameworks/*.xcframework', 'Frameworks/*.framework'
  s.static_framework = true
  
  # Flutter.framework does NOT contain a i386 slice.
  # Rapid_Kit does NOT support running on any iOS simulator.
  s.pod_target_xcconfig = {
  'DEFINES_MODULE' => 'YES',
  'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64 arm64'
   }

  s.swift_version = '5.0'
end
