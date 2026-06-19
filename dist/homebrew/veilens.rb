class Veilens < Formula
  desc "CLI for the veilens personal data vault (millrace server + headgate)"
  homepage "https://github.com/veilensapp/cli"
  # version / url / sha256 are bumped per release by dist/homebrew/update-formula.sh
  # (downloads the veilens-macos.tar.gz release asset and fills in its checksum).
  version "0.1.5"
  url "https://github.com/veilensapp/cli/releases/download/v0.1.5/veilens-macos.tar.gz"
  sha256 "53ec42ee71b3c9ee15056dcb2194ea546a9450f4575c75199ac77c5f13692db6"

  depends_on :macos

  def install
    # The tarball is a single universal (arm64 + x86_64) `veilens` binary.
    bin.install "veilens"
  end

  test do
    assert_match "veilens", shell_output("#{bin}/veilens --help")
  end
end
