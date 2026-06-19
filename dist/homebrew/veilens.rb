class Veilens < Formula
  desc "CLI for the veilens personal data vault (millrace server + headgate)"
  homepage "https://github.com/veilensapp/cli"
  # version / url / sha256 are bumped per release by dist/homebrew/update-formula.sh
  # (downloads the veilens-macos.tar.gz release asset and fills in its checksum).
  version "0.1.6"
  url "https://github.com/veilensapp/cli/releases/download/v0.1.6/veilens-macos.tar.gz"
  sha256 "7ce3ce2ad7318dbf88d5d0762be48aaf93bf2ec39922665b3a504ab35fe4981d"

  depends_on :macos

  def install
    # The tarball is a single universal (arm64 + x86_64) `veilens` binary.
    bin.install "veilens"
  end

  test do
    assert_match "veilens", shell_output("#{bin}/veilens --help")
  end
end
