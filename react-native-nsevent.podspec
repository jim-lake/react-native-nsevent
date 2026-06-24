require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-nsevent"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://github.com/user/react-native-nsevent"
  s.license      = package["license"]
  s.author       = "Author"
  s.source       = { :git => "https://github.com/user/react-native-nsevent.git", :tag => s.version }

  s.osx.deployment_target = "11.0"

  s.source_files = "macos/**/*.{h,cpp,mm}"

  install_modules_dependencies(s)
end
