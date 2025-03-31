class Swiftgraphql < Formula
  desc "Code generator for SwiftGraphQL library"
  homepage "https://swift-graphql.org"
  license "MIT"
  version "5.1.2"
  
  url "file:///Users/bryananderson/Developer/Forks/swift-graphql", :using => :git, :branch => "swift-6-concurrency"
  
  depends_on :xcode
  uses_from_macos "libxml2"
  uses_from_macos "swift"

  def install
    system "swift", "build", "-c", "release", "--product", "swift-graphql"
    bin.install ".build/release/swift-graphql"
  end

  test do
    system "#{bin}/swift-graphql", "--version"
  end
end