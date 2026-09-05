//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyConfig.h
//  MacViKey — cấu hình biên dịch
//
//  Tập trung toàn bộ các quyết định "rút gọn giao diện" vào một chỗ,
//  để dễ bật/tắt và dễ đối chiếu lại với dự án gốc (xem NOTICE.md).
//
//  Copyright © 2026 Do Hoang Dat
//
//  This file is part of MacViKey.
//
//  MacViKey is free software: you can redistribute it and/or modify it under
//  the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option)
//  any later version.
//
//  MacViKey is distributed in the hope that it will be useful, but WITHOUT ANY
//  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//  FOR A PARTICULAR PURPOSE. See the GNU General Public License for details.
//
//  You should have received a copy of the GNU General Public License along
//  with MacViKey. If not, see <https://www.gnu.org/licenses/>.
//

#ifndef MacViKeyConfig_h
#define MacViKeyConfig_h

// Chỉ cho phép duy nhất 1 kiểu gõ và 1 bảng mã.
// Ẩn Telex, VNI, Simple Telex 2, TCVN3, VNI Windows, Unicode tổ hợp, CP 1258.
#define MACVIKEY_LOCK_INPUT_TYPE_AND_CODE   1

// Ẩn "Công cụ chuyển mã..." và "Chuyển mã nhanh" (kể cả phím tắt).
#define MACVIKEY_HIDE_CONVERT_TOOL          1

// Ẩn khỏi GUI và khoá về TẮT một số tuỳ chọn engine:
//   A5  vCheckSpelling        - kiểm tra chính tả
//   A6  vUseModernOrthography - kiểu bỏ dấu mới (oà/uý)
//   A7  vQuickTelex           - gõ tắt phụ âm (cc->ch, gg->gi...)
//   A11 vQuickEndConsonant    - phụ âm cuối nhanh (g->ng, h->nh, k->ch)
//   A8  vRestoreIfWrongSpelling - khôi phục nếu gõ sai (chỉ có nghĩa khi A5 bật)
//   A13 vTempOffSpelling      - tạm tắt chính tả bằng Ctrl
#define MACVIKEY_HIDE_ENGINE_OPTIONS        1

// Giá trị bị khoá cứng.
// vInputType: 0=Telex, 1=VNI, 2=Simple Telex 1, 3=Simple Telex 2
#define MACVIKEY_FIXED_INPUT_TYPE           2
// vCodeTable: 0=Unicode dựng sẵn, 1=TCVN3, 2=VNI Windows, 3=Unicode tổ hợp, 4=CP1258
#define MACVIKEY_FIXED_CODE_TABLE           0

// An hoan toan tinh nang Go tat (macro): menu "Go tat...", tab "Go tat" trong bang
// dieu khien, va cua so bang go tat.
#define MACVIKEY_HIDE_MACRO                 1

// Chuyen toan bo tuy chon tu bang dieu khien len menu tren thanh trang thai.
// Bang dieu khien chi con tab "Thong tin".
#define MACVIKEY_MENUBAR_OPTIONS            1

// Phim chuyen: chi con 4 to hop co dinh (bit theo Engine.h + bit fn rieng cua macOS).
#define MACVIKEY_FN_FLAG                    0x1000
#define MACVIKEY_HAS_FN(data)               ((data & MACVIKEY_FN_FLAG) ? 1 : 0)
// Hotkey chi gom phim bo tro: khong co keycode -> 0xFE ca o byte thap lan byte cao.
#define MACVIKEY_SWITCH_BASE                0xFE0000FE
// Luon keu beep khi doi che do (bit 0x8000).
#define MACVIKEY_SWITCH_BEEP                0x8000
#define MACVIKEY_SWITCH_CMD_SHIFT           (MACVIKEY_SWITCH_BASE | 0x400 | 0x800 | MACVIKEY_SWITCH_BEEP)
#define MACVIKEY_SWITCH_OPT_SHIFT           (MACVIKEY_SWITCH_BASE | 0x200 | 0x800 | MACVIKEY_SWITCH_BEEP)
#define MACVIKEY_SWITCH_CTRL_SHIFT          (MACVIKEY_SWITCH_BASE | 0x100 | 0x800 | MACVIKEY_SWITCH_BEEP)
#define MACVIKEY_SWITCH_FN_SHIFT            (MACVIKEY_SWITCH_BASE | MACVIKEY_FN_FLAG | 0x800 | MACVIKEY_SWITCH_BEEP)
#define MACVIKEY_SWITCH_DEFAULT             MACVIKEY_SWITCH_CTRL_SHIFT

// An muc "Bang dieu khien..." khoi menu thanh trang thai. Bang van mo duoc qua
// tuy chon "Mo bang dieu khien khi khoi dong" hoac bam vao icon tren Dock.
#define MACVIKEY_HIDE_CONTROL_PANEL         1

// Thanh menu chi hien chu VI / EN, khong dung bieu tuong anh.
#define MACVIKEY_STATUS_TEXT_ONLY           1

// Bien dich duong Accessibility (thay the van ban nguyen tu, khong gia lap phim).
// Bat = luon dung, khong co tuy chon luc chay: MacViKeyInit() goi thang
// MacViKeyAXSetEnabled(YES). Muon tat thi doi co nay ve 0.
#define MACVIKEY_ENABLE_AX_PATH             1

#define MACVIKEY_INPUT_TYPE_NAME            @"Simple Telex"
#define MACVIKEY_CODE_TABLE_NAME            @"Unicode dựng sẵn"

#endif /* MacViKeyConfig_h */
