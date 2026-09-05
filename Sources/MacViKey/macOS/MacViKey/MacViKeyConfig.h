//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyConfig.h
//  MacViKey — hằng số cấu hình
//
//  Cac gia tri bi khoa cung cua ban rut gon: kieu go, bang ma va phim chuyen.
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

// Gia tri bi khoa cung.
// vInputType: 0=Telex, 1=VNI, 2=Simple Telex 1, 3=Simple Telex 2
#define MACVIKEY_FIXED_INPUT_TYPE           2
// vCodeTable: 0=Unicode dung san, 1=TCVN3, 2=VNI Windows, 3=Unicode to hop, 4=CP1258
#define MACVIKEY_FIXED_CODE_TABLE           0

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

#define MACVIKEY_INPUT_TYPE_NAME            @"Simple Telex"
#define MACVIKEY_CODE_TABLE_NAME            @"Unicode dựng sẵn"

#endif /* MacViKeyConfig_h */
