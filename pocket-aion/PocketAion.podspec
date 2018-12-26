#
#  Be sure to run `pod spec lint PocketAion.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # Meta
  s.name         = "PocketAion"
  s.version      = "0.0.1"
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/pokt-network/pocket-ios-aion'
  s.author       = { "Pabel Nunez L." => "pabel@pokt.network'", 'Luis C. de Leon' => 'luis@pokt.network' }
  s.summary      = "An Aion Plugin for the Pocket iOS SDK."

  # Settings
  s.source       = { :git => "http://EXAMPLE/PocketAion.git", :tag => "#{s.version}" }
  s.source_files      = 'pocket-aion/**/*.{swift}'
  s.exclude_files     = 'docs/*', 'pocket-aionTests/**/*.{swift}'
  s.swift_version     = '4.0'
  s.cocoapods_version = '>= 1.4.0'

  # Deployment Targets
  s.ios.deployment_target = '11.4'
  s.dependency 'Pocket', '~> 0.0.3'

end
