Pod::Spec.new do |s|
  s.name = 'CoreAPI'

  s.version = '1.0.0'
  
  s.homepage = "https://github.com/naftaly/CoreAPI"
  s.source = { :git => "https://github.com/naftaly/CoreAPI.git", :tag => "master" }
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'Simple Networking framework.'

  s.social_media_url = 'https://twitter.com/naftaly'
  s.authors  = { 'Alexander Cohen' => 'naftaly@me.com' }

  s.requires_arc = true

  s.ios.deployment_target = '9.0'
	
  s.source_files = [ 'CoreAPI/*.h', 'CoreAPI/*.m' ]
  s.public_header_files = [ 'CoreAPI/*.h' ]
  
  s.dependency = 'CorePromise'
end
