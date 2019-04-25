
Pod::Spec.new do |s|
    s.name                  = "GroundSdk"
    s.version               = "0.22.0"
    s.summary               = "Parrot Drone SDK"
    s.homepage              = "https://developer.parrot.com"
    s.license               = "{ :type => 'BSD 3-Clause License', :file => 'LICENSE' }"
    s.author                = 'Parrot Drone SAS'
    s.source                = { :git => 'https://github.com/Parrot-Developers/pod_groundsdk.git', :tag => "0.22.0" }
    s.platform              = :ios
    s.ios.deployment_target = '10.0'
    s.source_files          = 'GroundSdk/**/*'
    s.dependency            'SdkCore', '0.22.0'
    s.public_header_files   = ["GroundSdk/GroundSdk.h"]
    s.swift_version         = '4.2'
    s.pod_target_xcconfig   = {'SWIFT_VERSION' => '4.2'}
    s.xcconfig              = { 'ONLY_ACTIVE_ARCH' => 'YES' }
end
