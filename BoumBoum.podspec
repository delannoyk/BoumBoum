Pod::Spec.new do |s|
  s.name         = 'BoumBoum'
  s.version      = '0.1.1'
  s.license      =  { :type => 'MIT' }
  s.homepage     = 'https://github.com/delannoyk/BoumBoum'
  s.authors      = {
    'Kevin Delannoy' => 'delannoyk@gmail.com'
  }
  s.summary      = 'BoumBoum is an iOS framework that measure heart beat rate from the camera.'

# Source Info
  s.source       =  {
    :git => 'https://github.com/delannoyk/BoumBoum.git',
    :tag => s.version.to_s
  }
  s.source_files = 'sources/BoumBoum/**/*.swift'

  s.ios.deployment_target = '8.0'

  s.requires_arc = true
end
