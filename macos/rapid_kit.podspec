#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rapid_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rapid_kit'
  s.version          = '1.8.0-alpha.12'
  s.summary          = 'Real-time Audio-visual Platform for IoT Devices by tange-ai'
  s.description      = <<-DESC
Real-time Audio-visual Platform for IoT Devices by tangde-ai
                       DESC
  s.homepage         = 'https://tange.ai/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'fengjun' => 'fengjun.dev@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.vendored_frameworks = 'Frameworks/*.xcframework'

  s.platform = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.frameworks = ['CoreBluetooth']
end
