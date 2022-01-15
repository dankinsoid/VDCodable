Pod::Spec.new do |s|
s.name             = 'VDCodable'
s.version          = '2.6.0'
s.summary          = 'A short description of VDCodable.'

s.description      = <<-DESC
TODO: Add long description of the pod here.
DESC

s.homepage         = 'https://github.com/dankinsoid/VDCodable'
# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'voidilov' => 'voidilov@gmail.com' }
s.source           = { :git => 'https://github.com/dankinsoid/VDCodable.git', :tag => s.version.to_s }

s.ios.deployment_target = '10.0'
s.swift_versions = '5.0'
s.source_files = 'Sources/VDCodable/**/*'

end