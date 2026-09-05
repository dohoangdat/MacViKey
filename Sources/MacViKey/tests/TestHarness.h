//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  TestHarness.h - MacViKey
//
//  Mô phỏng lớp macOS (MacViKeyHook.mm) bằng C++ thuần, để test engine mà không
//  cần macOS, không cần Xcode, không cần quyền Accessibility.
//
//  Ý tưởng: MacViKeyHook.mm đọc pData->backspaceCount và pData->charData[] rồi bắn
//  CGEvent. Ở đây ta đọc đúng hai trường đó rồi ghi vào một std::u16string.
//  Nếu engine đúng thì chuỗi thu được phải bằng chuỗi người dùng nhìn thấy.
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

#ifndef TestHarness_h
#define TestHarness_h

#include <string>
#include <vector>
#include <map>
#include <codecvt>
#include <locale>
#include "../engine/Engine.h"

//Engine khai báo các biến này là extern; bình thường AppDelegate.m định nghĩa chúng.
//Trong test, ta định nghĩa ở đây và điều khiển trực tiếp.
int vLanguage = 1;
int vInputType = vSimpleTelex1;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 0;
int vUseModernOrthography = 0;
int vQuickTelex = 0;
int vSwitchKeyStatus = 0x7A000206;
int vRestoreIfWrongSpelling = 0;
int vFixRecommendBrowser = 1;
int vSendKeyStepByStep = 0;
int vUseSmartSwitchKey = 0;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 0;
int vOtherLanguage = 1;
int vTempOffEngineByHotKey = 0;

//pData bình thường do MacViKeyHook.mm định nghĩa; ở đây ta tự giữ, lấy từ vKeyInit().
vKeyHookState* pData = nullptr;

namespace mvk {

// Bàn phím Mỹ: ký tự -> mã phím macOS (lấy từ engine/platforms/mac.h)
inline const std::map<char, Uint16>& keyMap() {
    static const std::map<char, Uint16> m = {
        {'a',KEY_A},{'b',KEY_B},{'c',KEY_C},{'d',KEY_D},{'e',KEY_E},{'f',KEY_F},
        {'g',KEY_G},{'h',KEY_H},{'i',KEY_I},{'j',KEY_J},{'k',KEY_K},{'l',KEY_L},
        {'m',KEY_M},{'n',KEY_N},{'o',KEY_O},{'p',KEY_P},{'q',KEY_Q},{'r',KEY_R},
        {'s',KEY_S},{'t',KEY_T},{'u',KEY_U},{'v',KEY_V},{'w',KEY_W},{'x',KEY_X},
        {'y',KEY_Y},{'z',KEY_Z},
        {'0',KEY_0},{'1',KEY_1},{'2',KEY_2},{'3',KEY_3},{'4',KEY_4},
        {'5',KEY_5},{'6',KEY_6},{'7',KEY_7},{'8',KEY_8},{'9',KEY_9},
        {' ',KEY_SPACE},{'.',KEY_DOT},{',',KEY_COMMA},{'/',KEY_SLASH},
        {'-',KEY_MINUS},{'[',KEY_LEFT_BRACKET},{']',KEY_RIGHT_BRACKET},
    };
    return m;
}

/**
 * Áp dụng kết quả engine lên "màn hình ảo".
 * Đây là bản sao logic của SendNewCharString() trong MacViKeyHook.mm,
 * nhánh vCodeTable == 0 (Unicode dựng sẵn).
 */
inline void applyResult(std::u16string& screen, Uint16 keycode, bool caps) {
    if (pData->code == vDoNothing)
        return;

    if (pData->code == vWillProcess || pData->code == vRestore ||
        pData->code == vRestoreAndStartNewSession) {

        // Bước 3: xoá
        for (int i = 0; i < pData->backspaceCount && !screen.empty(); i++)
            screen.pop_back();

        // Bước 4: gõ lại (charData xếp NGƯỢC - phần tử cuối là ký tự đầu)
        for (int k = pData->newCharCount - 1; k >= 0; k--) {
            Uint32 ch = pData->charData[k];
            if (ch & PURE_CHARACTER_MASK)
                screen.push_back((char16_t)(ch & CHAR_MASK));
            else if (!(ch & CHAR_CODE_MASK))
                screen.push_back((char16_t)keyCodeToCharacter(ch));
            else
                screen.push_back((char16_t)(ch & CHAR_MASK));
        }

        // Phím vừa bấm được trả lại nguyên trạng khi engine yêu cầu khôi phục
        if (pData->code == vRestore || pData->code == vRestoreAndStartNewSession) {
            Uint16 c = keyCodeToCharacter(keycode | (caps ? CAPS_MASK : 0));
            if (c != 0) screen.push_back((char16_t)c);
        }
        if (pData->code == vRestoreAndStartNewSession)
            startNewSession();
    }
}

/**
 * Gõ một chuỗi phím, trả về chuỗi hiện trên "màn hình".
 * Chữ HOA trong input = giữ Shift.
 */
inline std::string type(const std::string& keys) {
    if (pData == nullptr) pData = (vKeyHookState*)vKeyInit();
    startNewSession();
    std::u16string screen;

    for (char c : keys) {
        bool caps = (c >= 'A' && c <= 'Z');
        char lower = caps ? (char)(c - 'A' + 'a') : c;

        auto it = keyMap().find(lower);
        if (it == keyMap().end()) continue;
        Uint16 kc = it->second;

        //Giong MacViKeyHook.mm: che do tieng Anh thi callback tra ve som,
        //engine khong he duoc goi.
        if (vLanguage == 0) {
            Uint16 ch = keyCodeToCharacter(kc | (caps ? CAPS_MASK : 0));
            if (ch != 0) screen.push_back((char16_t)ch);
            else if (lower == ' ') screen.push_back(u' ');
            continue;
        }

        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, kc, caps ? 1 : 0, false);

        if (pData->code == vDoNothing) {
            // engine bỏ qua -> ký tự đi thẳng lên màn hình như phím thường
            Uint16 ch = keyCodeToCharacter(kc | (caps ? CAPS_MASK : 0));
            if (ch != 0) screen.push_back((char16_t)ch);
            else if (lower == ' ') screen.push_back(u' ');
        } else {
            applyResult(screen, kc, caps);
        }
    }

    std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t> cvt;
    return cvt.to_bytes(screen);
}

/** Đặt lại toàn bộ tuỳ chọn về đúng cấu hình MacViKey xuất xưởng. */
inline void resetToMacViKeyDefaults() {
    if (pData == nullptr) pData = (vKeyHookState*)vKeyInit();
    vLanguage = 1;
    vInputType = vSimpleTelex1;
    vCodeTable = 0;
    vCheckSpelling = 0;          // A5 - đã tắt vĩnh viễn
    vUseModernOrthography = 0;   // A6
    vQuickTelex = 0;             // A7
    vRestoreIfWrongSpelling = 0; // A8
    vQuickEndConsonant = 0;      // A11
    vTempOffSpelling = 0;        // A13
    vFreeMark = 0;
    vAllowConsonantZFWJ = 0;
    vQuickStartConsonant = 0;
    vUpperCaseFirstChar = 0;
    vSetCheckSpelling();
    startNewSession();
}

} // namespace mvk

#endif /* TestHarness_h */
