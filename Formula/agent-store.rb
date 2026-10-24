# Formula for the av/homebrew-tap repo (Formula/agent-store.rb).
# Binary-based: installs prebuilt release tarballs from GitHub Releases.
#
# After tagging a release, update the version in the three urls and their sha256. Compute each with:
#   curl -sL https://github.com/av/agent-store/releases/download/v0.1.3/agent-store-v0.1.3-x86_64-apple-darwin.sha256
# (each .tar.gz asset has a matching .sha256 asset; the checksum is the first field)
# Or use scripts/update-formula.sh vX.Y.Z in the tap repo (it fails if the assets are missing).
class AgentStore < Formula
  desc "Persistent, queryable memory for coding agents"
  homepage "https://github.com/av/agent-store"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/av/agent-store/releases/download/v0.1.3/agent-store-v0.1.3-aarch64-apple-darwin.tar.gz"
      sha256 "bba69df972259aa694e8101cf88fbfbf5e8cf6a2175a17e8c1136587dea5f51f"
    else
      url "https://github.com/av/agent-store/releases/download/v0.1.3/agent-store-v0.1.3-x86_64-apple-darwin.tar.gz"
      sha256 "e6ec2b8dc496d10fc964c72415b97848bd043f71b22449bbd6723e40fcf117a9"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/av/agent-store/releases/download/v0.1.3/agent-store-v0.1.3-x86_64-unknown-linux-musl.tar.gz"
      sha256 "6fb74b6303448edc59e1f2e6449613401f4ced5b15dcd4edc80b970a4a57d7dc"
    else
      odie "agent-store: no prebuilt Linux binary for #{Hardware::CPU.arch}"
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
