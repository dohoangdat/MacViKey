//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  test_engine.cpp - MacViKey
//  Lưới an toàn hồi quy cho engine tiếng Việt.
//  Chạy: make test        (không cần Xcode, không cần macOS API)
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
#include <cstdio>
#include <string>
#include "TestHarness.h"

static int g_pass = 0, g_fail = 0;

static void GROUP(const char* name) { printf("\n\033[1m%s\033[0m\n", name); }

static void CHECK(const std::string& keys, const std::string& expect) {
    std::string got = mvk::type(keys);
    if (got == expect) {
        g_pass++;
        printf("  \033[32m✓\033[0m  %-16s → %s\n", keys.c_str(), got.c_str());
    } else {
        g_fail++;
        printf("  \033[31m✗\033[0m  %-16s → \033[31m%s\033[0m   (mong đợi \033[32m%s\033[0m)\n",
               keys.c_str(), got.c_str(), expect.c_str());
    }
}

int main() {
    vKeyInit();
    printf("\n\033[1m═══ MacViKey · Test hồi quy engine ═══\033[0m\n");
    printf("Cấu hình xuất xưởng: Simple Telex 1 · Unicode dựng sẵn · chính tả TẮT\n");

    GROUP("1 · Nguyên âm có mũ và móc");
    mvk::resetToMacViKeyDefaults();
    CHECK("aa", "â");   CHECK("ee", "ê");   CHECK("oo", "ô");
    CHECK("aw", "ă");   CHECK("ow", "ơ");   CHECK("uw", "ư");
    CHECK("uow", "ươ"); CHECK("dd", "đ");

    GROUP("2 · Năm dấu thanh (Telex: s f r x j)");
    mvk::resetToMacViKeyDefaults();
    CHECK("as", "á"); CHECK("af", "à"); CHECK("ar", "ả");
    CHECK("ax", "ã"); CHECK("aj", "ạ");

    GROUP("3 · Từ hoàn chỉnh");
    mvk::resetToMacViKeyDefaults();
    CHECK("tieengs",    "tiếng");
    CHECK("Vieetj",     "Việt");
    CHECK("nghieeng",   "nghiêng");
    CHECK("hoaf",       "hòa");
    CHECK("quyts",      "quýt");
    CHECK("nguowif",    "người");
    CHECK("cuoocj",     "cuộc");
    CHECK("dduwowngf",  "đường");

    GROUP("4 · Ca hồi quy trích từ CHANGELOG (bug từng được vá)");
    mvk::resetToMacViKeyDefaults();
    CHECK("quownr",  "quởn");   // v2.0.3
    CHECK("quets",   "quét");   // v2.0.2
    CHECK("dduowcj", "được");   // "duocd"
    CHECK("booong",  "boong");  // âm oong: gõ 3 chữ o - đúng thiết kế
    CHECK("booc",    "bôc");    // 2 chữ o vẫn ra ô
    CHECK("boooc",   "booc");   // âm ooc

    GROUP("5 · Viết hoa");
    mvk::resetToMacViKeyDefaults();
    CHECK("Tieengs", "Tiếng");
    CHECK("VIEETJ",  "VIỆT");
    CHECK("Dd",      "Đ");

    GROUP("6 · Nhiều từ và ngắt từ");
    mvk::resetToMacViKeyDefaults();
    CHECK("xin chaof",       "xin chào");
    CHECK("tieengs vieetj",  "tiếng việt");

    GROUP("7 · Tuỳ chọn đã khoá TẮT phải thực sự không hoạt động");
    mvk::resetToMacViKeyDefaults();
    CHECK("ccu",  "ccu");   // A7 gõ tắt phụ âm  → cc KHÔNG thành ch
    CHECK("hag",  "hag");   // A11 phụ âm cuối   → g  KHÔNG thành ng
    CHECK("hoaf", "hòa");   // A6 bỏ dấu mới     → KHÔNG ra "hoà"

    GROUP("8 · Simple Telex 1: phím W đứng một mình KHÔNG thành ư");
    mvk::resetToMacViKeyDefaults();
    CHECK("w",  "w");
    CHECK("wa", "wa");

    GROUP("9 · Chế độ tiếng Anh không được đụng vào phím nào");
    mvk::resetToMacViKeyDefaults();
    vLanguage = 0;
    CHECK("tieengs", "tieengs");
    CHECK("aa",      "aa");
    CHECK("dd",      "dd");
    vLanguage = 1;

    GROUP("10 · Bật lại chính tả (A5) không được làm hỏng kết quả");
    mvk::resetToMacViKeyDefaults();
    vCheckSpelling = 1; vSetCheckSpelling();
    CHECK("tieengs",   "tiếng");
    CHECK("dduowcj",   "được");
    CHECK("nguowif",   "người");
    mvk::resetToMacViKeyDefaults();

    GROUP("11 · Từ mượn bắt đầu bằng Z F W J (issue #327)");
    mvk::resetToMacViKeyDefaults();
    CHECK("zoos", "zố");    // chính tả TẮT → engine không chặn nữa
    CHECK("faan", "fân");
    CHECK("jees", "jế");

    GROUP("12 · Bảng mã bị khoá Unicode dựng sẵn (không ra tổ hợp)");
    mvk::resetToMacViKeyDefaults();
    // "ế" dựng sẵn là 1 ký tự U+1EBF; tổ hợp sẽ là 2 ký tự (e + dấu)
    CHECK("ees", "ế");
    CHECK("eej", "ệ");

    printf("\n\033[1m─────────────────────────────────────\033[0m\n");
    printf("  Đạt \033[32m%d\033[0m   ·   Hỏng %s%d\033[0m   ·   Tổng %d\n",
           g_pass, g_fail ? "\033[31m" : "\033[32m", g_fail, g_pass + g_fail);
    printf("\033[1m─────────────────────────────────────\033[0m\n\n");
    return g_fail ? 1 : 0;
}
