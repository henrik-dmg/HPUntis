Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "SwiftyUntis"
s.summary = "A lightweight wrapper for the Untis JSON API"
s.requires_arc = true

# 2
s.version = "1.0.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Henrik Panhans" => "henrikpanhans@icloud.com" }

# For example,
# s.author = { "Joshua Greene" => "jrg.developer@gmail.com" }


# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/Fri3ndlyGerman/SwiftyUntis"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/Fri3ndlyGerman/SwiftyUntis.git", :tag => "#{s.version}"}


# 7
s.framework = "UIKit"
s.dependency 'Alamofire'
s.dependency 'SwiftyJSON'

# 8
s.source_files = "SwiftyUntis/**/*.{swift}"

# 9
s.resources = "SwiftyUntis/**/*.{png,jpeg,jpg,storyboard,xib}"
end
