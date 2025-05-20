class Swiftgraphql < Formula
  desc "Code generator for SwiftGraphQL library"
  homepage "https://swift-graphql.org"
  license "MIT"
  version "6.0.15"
  
  url "https://github.com/bryan1anderson/swift-graphql/archive/6.0.15.tar.gz"
  sha256 "7f3e872e27b59282fafe8e5a59d2c4f4413f60b607d8adbddc327480eea6e149"
  
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