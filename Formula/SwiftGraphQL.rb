class Swiftgraphql < Formula
  desc "Code generator for SwiftGraphQL library"
  homepage "https://swift-graphql.org"
  license "MIT"
  version "6.0.3"
  
  url "https://github.com/bryan1anderson/swift-graphql/archive/refs/tags/6.0.3.tar.gz"
  sha256 "91dffe4d4ed1a89c6fef86ce5e28434fcaf83a1f4505728af6d025c8a8312516"
  
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