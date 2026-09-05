#!/usr/bin/env python3
"""Dung Icon.icns tu file logo cua app.

    python3 tools/make_icon.py [duong/dan/logo.png]

Mac dinh doc Sources/MacViKey/macOS/MacViKey/Resources/logo_macvikey.png va ghi
de Icon.icns ngay canh no. File logo goc KHONG bi sua.

Anh nguon co the o mot trong hai dang:
  - da co kenh alpha  -> dung nguyen
  - nen o ca-ro duoc in thang vao pixel (khong alpha) -> tu tach nen bang cach
    lan tu 4 bien qua cac pixel rat sang; vung sang nam trong long logo khong bi
    dung toi vi khong noi lien voi bien.
"""
import os
import subprocess
import sys
import tempfile
from collections import deque

import numpy as np
from PIL import Image

# Nen ca-ro do sang 237-255; cho sang nhat cua logo van thap hon nguong nay.
LIGHT_CUTOFF = 235
PADDING_RATIO = 0.05        # le quanh icon, theo thoi quen cua icon he thong
ICON_SIZES = (16, 32, 128, 256, 512)


def strip_baked_background(img):
    a = np.array(img)
    h, w, _ = a.shape
    light = a[:, :, :3].min(axis=2) >= LIGHT_CUTOFF
    seen = np.zeros((h, w), bool)
    queue = deque()

    def push(y, x):
        if light[y, x] and not seen[y, x]:
            seen[y, x] = True
            queue.append((y, x))

    for x in range(w):
        push(0, x)
        push(h - 1, x)
    for y in range(h):
        push(y, 0)
        push(y, w - 1)
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w:
                push(ny, nx)

    a[seen] = (0, 0, 0, 0)
    return Image.fromarray(a)


def build_master(src):
    img = Image.open(src).convert('RGBA')
    if np.array(img)[:, :, 3].min() == 255:
        # Khong co pixel trong suot nao -> nen chac chan la mau in thang vao anh.
        img = strip_baked_background(img)

    box = img.getbbox()
    if box is None:
        sys.exit('Anh rong: %s' % src)
    img = img.crop(box)

    side = max(img.size)
    pad = int(side * PADDING_RATIO)
    canvas = Image.new('RGBA', (side + 2 * pad,) * 2, (0, 0, 0, 0))
    canvas.paste(img, ((canvas.width - img.width) // 2,
                       (canvas.height - img.height) // 2), img)
    return canvas.resize((1024, 1024), Image.LANCZOS)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default = os.path.join(root, 'Sources/MacViKey/macOS/MacViKey/Resources/logo_macvikey.png')
    src = sys.argv[1] if len(sys.argv) > 1 else default
    dest = os.path.join(os.path.dirname(src), 'Icon.icns')

    master = build_master(src)
    with tempfile.TemporaryDirectory() as tmp:
        iconset = os.path.join(tmp, 'Icon.iconset')
        os.makedirs(iconset)
        for size in ICON_SIZES:
            master.resize((size, size), Image.LANCZOS).save(
                '%s/icon_%dx%d.png' % (iconset, size, size))
            master.resize((size * 2, size * 2), Image.LANCZOS).save(
                '%s/icon_%dx%d@2x.png' % (iconset, size, size))
        subprocess.run(['iconutil', '-c', 'icns', iconset, '-o', dest], check=True)

    print('Da dung xong: %s' % dest)


if __name__ == '__main__':
    main()
