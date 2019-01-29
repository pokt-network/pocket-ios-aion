# PocketAion
#
# Verifying:
# pod lib lint PocketAion.podspec --allow-warnings
#
# Releasing:
# pod repo push master PocketAion.podspec --allow-warnings

Pod::Spec.new do |s|

  # Meta
  s.name         = "PocketAion"
  s.version      = "0.0.6"
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/pokt-network/pocket-ios-aion'
  s.author       = { "Pabel Nunez L." => "pabel@pokt.network'", 'Luis C. de Leon' => 'luis@pokt.network' }
  s.summary      = "An Aion Plugin for the Pocket iOS SDK."

  # Settings
  s.source            = { :git => 'https://github.com/pokt-network/pocket-ios-aion.git', :tag => s.version.to_s }
  s.source_files      = 'pocket-aion/**/*.{swift}'
  s.exclude_files     = 'docs/*', 'pocket-aionTests/**/*.{swift}'
  s.swift_version     = '4.0'
  s.cocoapods_version = '>= 1.4.0'

  # Deployment Targets
  s.ios.deployment_target = '11.4'
  s.dependency 'Pocket', '~> 0.0.3'
  s.dependency 'BigInt', '~> 3.1'
  s.dependency 'SwiftyJSON', '~> 4.0'

end
