class Swiftgraphql < Formula
  desc "Code generator for SwiftGraphQL library"
  homepage "https://swift-graphql.org"
  license "MIT"
  version "6.0.1"
  
  url "https://github.com/bryan1anderson/swift-graphql/archive/refs/tags/6.0.1.tar.gz"
  sha256 "2510d795cc04862148abd99f4962cabf361019332a4254590ee43da8cf3e1611"
  
  depends_on :xcode
  uses_from_macos "libxml2"
  uses_from_macos "swift"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system "#{bin}/swift-graphql", "--version"
  end
end
