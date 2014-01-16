Pod::Spec.new do |s|

  s.name         = "ISListViewAdapter"
  s.version      = "0.0.1"
  s.summary      = "Adapter for managing UICollectionView and UITableView animations"
  s.homepage     = "https://github.com/jbmorley/ISListViewAdapter"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Jason Barrie Morley" => "jason.morley@inseven.co.uk" }
  s.source       = { :git => "https://github.com/jbmorley/ISListViewAdapter.git", :commit => "9e5284fb215fcbcd668dc0736306fde7214b20fc" }

  s.source_files = 'Classes/*.{h,m}'

  s.requires_arc = true

  s.platform = :ios, "6.0", :osx, "10.8"

end
