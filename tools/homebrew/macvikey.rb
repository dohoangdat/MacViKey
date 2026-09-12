# Mau cask cho repo tap rieng: github.com/dohoangdat/homebrew-tap
# Dat file nay tai Casks/macvikey.rb trong repo do.
#
# Moi lan phat hanh: cap nhat version + sha256 theo output cua tools/release.sh.
cask "macvikey" do
  version "1.1"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/dohoangdat/MacViKey/releases/download/v#{version}/MacViKey-#{version}.dmg"
  name "MacViKey"
  desc "Bo go tieng Viet gon nhe cho macOS"
  homepage "https://github.com/dohoangdat/MacViKey"

  depends_on macos: ">= :catalina"

  app "MacViKey.app"

  uninstall quit: "com.mac.vi.key"

  zap trash: [
    "~/Library/Preferences/com.mac.vi.key.plist",
    "~/Library/Application Support/MacViKey",
  ]

  caveats <<~EOS
    Cap quyen Tro nang cho MacViKey:
      Cai dat He thong > Quyen rieng tu & Bao mat > Tro nang > bat MacViKey

    Hay tat cac bo go tieng Viet khac de tranh xung dot.
  EOS
end
