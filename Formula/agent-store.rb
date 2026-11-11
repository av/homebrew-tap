# Formula for the av/homebrew-tap repo (Formula/agent-store.rb).
# Binary-based: installs prebuilt release tarballs from GitHub Releases.
#
# After tagging a release, update the version in the four urls and their sha256. Compute each with:
#   curl -sL https://github.com/av/agent-store/releases/download/v0.1.4/agent-store-v0.1.4-x86_64-apple-darwin.sha256
# (each .tar.gz asset has a matching .sha256 asset; the checksum is the first field)
# Or use scripts/update-formula.sh vX.Y.Z in the tap repo (it fails if the assets are missing).
class AgentStore < Formula
  desc "Persistent, queryable memory for coding agents"
  homepage "https://github.com/av/agent-store"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/av/agent-store/releases/download/v0.1.4/agent-store-v0.1.4-aarch64-apple-darwin.tar.gz"
      sha256 "9bba213ffd0dd975ef3d9eb544b841b387e95d7f15d05eb7be88326d61b73392"
    else
      url "https://github.com/av/agent-store/releases/download/v0.1.4/agent-store-v0.1.4-x86_64-apple-darwin.tar.gz"
      sha256 "12ff3555aa5781a75e61c61626c62a2fe2d3c509a6950b7c508a2b5037d1b7b8"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/av/agent-store/releases/download/v0.1.4/agent-store-v0.1.4-aarch64-unknown-linux-musl.tar.gz"
      sha256 "4d13fff76cd5e080c2232db8eab9c55c8641357d5cb3c051927588fcd7313273"
    else
      url "https://github.com/av/agent-store/releases/download/v0.1.4/agent-store-v0.1.4-x86_64-unknown-linux-musl.tar.gz"
      sha256 "2e8088a5b2e0ee6cd12137d7a2ec41154f0293c30a78f2cdd8a51acead13bd9f"
    end
  end

  def install
    bin.install "agent-store"
    man1.install "man/agent-store.1"
    bash_completion.install "completions/agent-store.bash" => "agent-store"
    zsh_completion.install "completions/_agent-store"
    fish_completion.install "completions/agent-store.fish"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/agent-store --version")
    system bin/"agent-store", "init"
    assert_predicate testpath/".agent-store", :directory?
    assert_match ".agent-store/", (testpath/".gitignore").read
    assert_path_exists testpath/".agents/skills/agent-store/SKILL.md"
    system bin/"agent-store", "create", "note", "title=hello"
    assert_path_exists testpath/".agent-store/store.sqlite"
    assert_match "title=hello", shell_output("#{bin}/agent-store find title=hello")
  end
end
