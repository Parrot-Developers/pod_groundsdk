
Pod::Spec.new do |s|
    s.name                  = "GroundSdk"
    s.version               = "7.0.1"
    s.summary               = "Parrot Drone SDK"
    s.homepage              = "https://developer.parrot.com"
    s.license               = "{ :type => 'BSD 3-Clause License', :file => 'LICENSE' }"
    s.author                = 'Parrot Drone SAS'
    s.source                = { :git => 'https://github.com/Parrot-Developers/pod_groundsdk.git', :tag => "7.0.1" }
    s.platform              = :ios
    s.ios.deployment_target = '12.0'
    s.source_files          = 'GroundSdk/**/*.{swift,h,m}'
    s.resources             = 'GroundSdk/**/*.{vsh,fsh,txt,png}'
    s.dependency            'SdkCore', '7.0.1'
    s.public_header_files   = ["GroundSdk/GroundSdk.h"]
    s.swift_version         = '5'
    s.pod_target_xcconfig   = {'SWIFT_VERSION' => '5'}
    s.xcconfig              = { 'ONLY_ACTIVE_ARCH' => 'YES' }
end
