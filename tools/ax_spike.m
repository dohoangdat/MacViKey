//
//  ax_spike.m - MacViKey
//
//  Kiểm tra xem app đang focus có cho phép thay thế văn bản qua Accessibility API
//  hay không. Đây là điều kiện tiên quyết cho "đường AX" - thay thế nguyên tử,
//  không cần giả lập Backspace.
//
//  Build: clang -fobjc-arc -framework Cocoa -framework ApplicationServices -o ax_spike ax_spike.m
//  Chạy : ./ax_spike            (cần cấp quyền Trợ năng cho Terminal)
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
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

static const char* ok(BOOL b) { return b ? "\033[32mCO\033[0m" : "\033[31mKHONG\033[0m"; }

int main(int argc, const char** argv) { @autoreleasepool {
    if (!AXIsProcessTrusted()) {
        printf("\n\033[31mChua co quyen Tro nang.\033[0m\n");
        printf("Cap quyen cho Terminal tai: Cai dat He thong > Quyen rieng tu & Bao mat > Tro nang\n\n");
        return 2;
    }

    int delay = (argc > 1) ? atoi(argv[1]) : 5;
    printf("\nBan co %d giay de chuyen sang app can kiem tra va dat con tro vao o nhap.\n", delay);
    printf("Hay go san vai ky tu (vi du: abcxyz)\n");
    for (int i = delay; i > 0; i--) { printf("\r  %d...  ", i); fflush(stdout); sleep(1); }
    printf("\r          \r");

    NSRunningApplication* app = [[NSWorkspace sharedWorkspace] frontmostApplication];
    printf("\nApp: \033[1m%s\033[0m (%s)\n\n",
           app.localizedName.UTF8String, app.bundleIdentifier.UTF8String);

    AXUIElementRef sys = AXUIElementCreateSystemWide();
    AXUIElementRef focused = NULL;
    AXError e = AXUIElementCopyAttributeValue(sys, kAXFocusedUIElementAttribute, (CFTypeRef*)&focused);

    BOOL hasFocused = (e == kAXErrorSuccess && focused != NULL);
    printf("  1. Lay duoc phan tu dang focus     : %s", ok(hasFocused));
    if (!hasFocused) { printf("  (AXError %d)\n\n", e); return 1; }
    printf("\n");

    // Doc gia tri hien tai
    CFTypeRef value = NULL;
    BOOL canRead = (AXUIElementCopyAttributeValue(focused, kAXValueAttribute, &value) == kAXErrorSuccess);
    printf("  2. Doc duoc noi dung o nhap        : %s", ok(canRead));
    if (canRead && CFGetTypeID(value) == CFStringGetTypeID())
        printf("  \"%.40s\"", [(__bridge NSString*)value UTF8String]);
    printf("\n");

    // Doc vi tri con tro
    CFTypeRef rangeVal = NULL;
    BOOL canReadRange = (AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute, &rangeVal) == kAXErrorSuccess);
    CFRange caret = {0,0};
    if (canReadRange) AXValueGetValue((AXValueRef)rangeVal, kAXValueCFRangeType, &caret);
    printf("  3. Doc duoc vi tri con tro         : %s", ok(canReadRange));
    if (canReadRange) printf("  (vi tri %ld, chon %ld)", caret.location, caret.length);
    printf("\n");

    // Thu boi den 3 ky tu cuoi va ghi de - day la thao tac that su can cho bo go
    BOOL canReplace = NO;
    if (canReadRange && caret.location >= 3) {
        CFRange target = { caret.location - 3, 3 };
        AXValueRef tRange = AXValueCreate(kAXValueCFRangeType, &target);
        AXError e1 = AXUIElementSetAttributeValue(focused, kAXSelectedTextRangeAttribute, tRange);
        AXError e2 = kAXErrorFailure;
        if (e1 == kAXErrorSuccess)
            e2 = AXUIElementSetAttributeValue(focused, kAXSelectedTextAttribute, CFSTR("ếữ%"));
        canReplace = (e1 == kAXErrorSuccess && e2 == kAXErrorSuccess);
        CFRelease(tRange);
        printf("  4. \033[1mTHAY THE duoc van ban\033[0m            : %s", ok(canReplace));
        if (!canReplace) printf("  (set range %d, set text %d)", e1, e2);
        printf("\n");
    } else {
        printf("  4. \033[1mTHAY THE duoc van ban\033[0m            : \033[33mBO QUA\033[0m (can it nhat 3 ky tu truoc con tro)\n");
    }

    printf("\n  ==> Ket luan: app nay %s dung duong AX.\n\n",
           canReplace ? "\033[32mDUNG DUOC\033[0m" : "\033[31mKHONG dung duoc -> phai fallback CGEventTap\033[0m");

    if (focused) CFRelease(focused);
    CFRelease(sys);
    return canReplace ? 0 : 1;
}}
