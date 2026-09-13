# Ban that dang chay tai: github.com/dohoangdat/homebrew-tap -> Casks/macvikey.rb
# Moi lan phat hanh: cap nhat version + sha256 theo output cua tools/release.sh,
# roi copy file nay sang repo tap.
cask "macvikey" do
  version "1.2"
  sha256 "87cbd116997ec47e4b1c66df69867a0ef6b18653095dcb16dfd37b12a88f37e1"

  url "https://github.com/dohoangdat/MacViKey/releases/download/v#{version}/MacViKey-#{version}.dmg"
  name "MacViKey"
  desc "Vietnamese input method"
  homepage "https://github.com/dohoangdat/MacViKey"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :big_sur

  app "MacViKey.app"

  uninstall quit: "com.mac.vi.key"

  zap trash: [
    "~/Library/Application Support/MacViKey",
    "~/Library/Preferences/com.mac.vi.key.plist",
  ]

  caveats <<~EOS
    Cấp quyền Trợ năng cho MacViKey:
      Cài đặt Hệ thống > Quyền riêng tư & Bảo mật > Trợ năng > bật MacViKey

    Hãy tắt các bộ gõ tiếng Việt khác để tránh xung đột.
  EOS
end
