# Formula for the av/homebrew-tap repo (Formula/agent-store.rb).
# Binary-based: installs prebuilt release tarballs from GitHub Releases.
#
# After tagging a release, fill in the sha256 placeholders. Compute each with:
#   curl -sL https://github.com/av/agent-store/releases/download/v0.1.0/agent-store-v0.1.0-x86_64-apple-darwin.sha256
# (each .tar.gz asset has a matching .sha256 asset; the checksum is the first field)
# Or use scripts/update-formula.sh in the tap repo.
class AgentStore < Formula
  desc "Local-first memory and context store for AI coding agents, backed by SQLite"
  homepage "https://github.com/av/agent-store"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/av/agent-store/releases/download/v#{version}/agent-store-v#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "832b6351f0e6ddde640049114e86b7878db362d31bc15d8ee7c526bdcb952c0f"
    else
      url "https://github.com/av/agent-store/releases/download/v#{version}/agent-store-v#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "290998206b50de712be4ea1a2935950be34fd783055c97b2ed2a075ff25889d4"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/av/agent-store/releases/download/v#{version}/agent-store-v#{version}-x86_64-unknown-linux-musl.tar.gz"
      sha256 "b1694921b8efbb333bb4c88eb756ae17775e7e46342ff1fc6864976b24f88370"
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
    assert_predicate testpath/".agent-store/store.sqlite", :exist?
  end
end
