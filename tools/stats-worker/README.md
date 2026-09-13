# MacViKey Stats Worker

Gom so lieu **Muc A** — tuc la nhung con so lay duoc tu ha tang phat hanh,
trong khi ban than app khong gui bat cu thu gi len server nao.

Worker khong nhan du lieu tu app. No chi doc ba nguon cong khai:

| Nguon | Cho con so gi |
|---|---|
| GitHub Releases API | Luot tai tung file DMG, cong don va theo tung ban |
| GitHub Repo API | Sao, fork |
| `formulae.brew.sh` | Luot cai qua Homebrew 30/90/365 ngay |

> **Luu y ve Homebrew.** Chi cask nam trong repo `homebrew-cask` **chinh thuc**
> moi co so lieu. Tap rieng `dohoangdat/homebrew-tap` tra ve 404, va o widget
> se hien dau `—` kem chu "chua co du lieu". Muon co so nay thi phai submit
> cask len homebrew-cask upstream.

## Cai dat

```sh
cd tools/stats-worker
npm i -g wrangler          # neu chua co
wrangler login
```

Tao GitHub token chi can quyen doc repo cong khai (`public_repo`), roi:

```sh
wrangler secret put GITHUB_TOKEN
```

Khong co token van chay duoc, nhung GitHub gioi han 60 request/gio cho mot dia
chi IP dung chung cua Cloudflare — rat de bi chan. Co token la 5000/gio.

```sh
wrangler deploy
```

## Cac duong dan

| Duong dan | Tra ve |
|---|---|
| `/` | Widget HTML de nhung bang `<iframe>` |
| `/stats.json` | Du lieu tho, CORS mo |
| `/badge.svg` | Badge kieu shields |

Tham so cua widget:

- `?theme=auto\|light\|dark` — mac dinh `auto`, theo cai dat cua nguoi xem
- `?lang=vi\|en` — mac dinh `vi`
- `?compact=1` — bo o "Ban moi nhat", con ba o

Tham so cua badge:

- `?metric=downloads\|installs\|stars`
- `?label=...` va `?color=%23d98533`

## Nhung vao website

Cach don gian nhat, chieu cao co dinh:

```html
<iframe src="https://macvikey-stats.<tai-khoan>.workers.dev/?theme=auto"
        style="width:100%;height:150px;border:0" loading="lazy"
        title="Thong ke MacViKey"></iframe>
```

Muon iframe tu co gian theo noi dung — widget tu bao chieu cao ve trang cha:

```html
<iframe id="mvk-stats" src="https://macvikey-stats.<tai-khoan>.workers.dev/"
        style="width:100%;height:150px;border:0" loading="lazy"
        title="Thong ke MacViKey"></iframe>
<script>
  addEventListener('message', function (e) {
    if (e.data && e.data.type === 'macvikey-stats-height') {
      document.getElementById('mvk-stats').style.height = e.data.height + 'px';
    }
  });
</script>
```

Badge cho README:

```markdown
![Luot tai](https://macvikey-stats.<tai-khoan>.workers.dev/badge.svg?metric=downloads)
```

## Chi phi va gioi han

Goi mien phi cua Cloudflare Workers cho 100.000 request/ngay. Worker cache ket
qua 1 gio o bien nen so lan goi GitHub API rat thap — thuc te khoang 24
request/ngay cho moi khu vuc co luot xem.

## Rieng tu

Worker khong ghi log, khong dat cookie, khong doc gi tu nguoi xem widget.
Con so hien ra la so lieu phat hanh cong khai, ai cung tu kiem chung duoc bang
GitHub API.
