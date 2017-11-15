Pod::Spec.new do |s|

  s.name                 = "UMActionController"
  s.version              = "1.0.1"
  s.platform             = :ios, '9.0'
  s.summary              = "This is an iOS control for presenting any UIView in an UIAlertController like manner"
  s.description          = "This framework allows you to present just any view as an action sheet. In addition, it allows you to add actions arround the presented view which behave like a button and can be tapped by the user. The result looks very much like an UIActionSheet or UIAlertController with a special UIView and some UIActions attached."
  
  s.homepage             = "https://github.com/ramonvic/UMActionController"
  
  s.license              = { :type => "MIT", :file => "LICENSE.md" }
  s.author               = { "Ramon Vicente" => "ramonvic@me.com" }
  
  s.source               = { :git => "https://github.com/ramonvic/UMActionController.git", :tag => "1.0.1" }
  s.source_files         = 'UMActionController/**/*.{swift}'
  
  s.requires_arc         = true
  s.framework            = 'CoreGraphics', 'QuartzCore'
end