class Swiftgraphql < Formula
  desc "Code generator for SwiftGraphQL library"
  homepage "https://swift-graphql.org"
  license "MIT"
  version "6.0.1"
  
  url "https://github.com/bryan1anderson/swift-graphql/archive/refs/tags/6.0.1.tar.gz"
  sha256 "PUT_SHA256_HERE"
  
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