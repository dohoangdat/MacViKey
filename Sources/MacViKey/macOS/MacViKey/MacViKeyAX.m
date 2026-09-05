//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyAX.m
//  MacViKey
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
#import "MacViKeyAX.h"
#import "MacViKeyConfig.h"

// Kết quả dò khả năng của một app
typedef NS_ENUM(NSInteger, MVKAXSupport) {
    MVKAXUnknown = 0,
    MVKAXSupported,
    MVKAXUnsupported,
};

static BOOL                  _axEnabled          = NO;
static AXUIElementRef        _sysWide            = NULL;
static NSMutableDictionary*  _supportByBundle    = nil;   // bundleId -> MVKAXSupport
static NSString*             _currentBundle      = @"";
static MVKAXSupport          _currentSupport     = MVKAXUnknown;
static int                   _successCount       = 0;
static int                   _fallbackCount      = 0;

// RẤT QUAN TRỌNG: lời gọi AX là IPC sang app đích. Nếu app đó đang bận,
// lời gọi có thể treo - mà ta đang đứng trong event tap callback, nơi
// macOS sẽ tắt tap nếu quá chậm. Timeout ngắn là bắt buộc.
static const float kAXTimeoutSeconds = 0.05f;   // 50ms

static void ensureInit(void) {
    if (_sysWide == NULL) {
        _sysWide = AXUIElementCreateSystemWide();
        AXUIElementSetMessagingTimeout(_sysWide, kAXTimeoutSeconds);
    }
    if (_supportByBundle == nil)
        _supportByBundle = [NSMutableDictionary dictionary];
}

BOOL MacViKeyAXIsEnabled(void) {
    return _axEnabled;
}

void MacViKeyAXSetEnabled(BOOL on) {
    _axEnabled = on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"vUseAccessibilityPath"];
    if (on) ensureInit();
}

/// Lấy phần tử đang focus, đã đặt timeout.
static AXUIElementRef copyFocusedElement(void) {
    ensureInit();
    AXUIElementRef focused = NULL;
    AXError e = AXUIElementCopyAttributeValue(_sysWide, kAXFocusedUIElementAttribute,
                                              (CFTypeRef*)&focused);
    if (e != kAXErrorSuccess || focused == NULL)
        return NULL;
    AXUIElementSetMessagingTimeout(focused, kAXTimeoutSeconds);
    return focused;
}

/// Dò khả năng KHÔNG phá huỷ: chỉ hỏi xem hai thuộc tính cần thiết có ghi được không.
static MVKAXSupport probeSupport(void) {
    AXUIElementRef focused = copyFocusedElement();
    if (focused == NULL)
        return MVKAXUnsupported;

    Boolean canSetRange = false, canSetText = false;
    AXError e1 = AXUIElementIsAttributeSettable(focused, kAXSelectedTextRangeAttribute, &canSetRange);
    AXError e2 = AXUIElementIsAttributeSettable(focused, kAXSelectedTextAttribute, &canSetText);
    CFRelease(focused);

    BOOL good = (e1 == kAXErrorSuccess && canSetRange &&
                 e2 == kAXErrorSuccess && canSetText);
    return good ? MVKAXSupported : MVKAXUnsupported;
}

void MacViKeyAXOnAppChanged(NSString* bundleId) {
    if (!_axEnabled || bundleId == nil) return;
    ensureInit();

    _currentBundle = [bundleId copy];
    NSNumber* cached = _supportByBundle[_currentBundle];
    if (cached != nil) {
        _currentSupport = (MVKAXSupport)[cached integerValue];
        return;
    }
    // Chưa biết -> để lần gõ đầu tiên tự dò, tránh phí thời gian khi chỉ chuyển app.
    _currentSupport = MVKAXUnknown;
}

BOOL MacViKeyAXReplaceText(int backspaceCount, NSString* newText) {
    if (!_axEnabled) return NO;
    if (backspaceCount < 0 || newText == nil) return NO;

    // App đã bị đánh dấu không hỗ trợ -> khỏi thử, khỏi tốn thời gian.
    if (_currentSupport == MVKAXUnsupported) {
        _fallbackCount++;
        return NO;
    }

    ensureInit();

    if (_currentSupport == MVKAXUnknown) {
        _currentSupport = probeSupport();
        if (_currentBundle.length > 0)
            _supportByBundle[_currentBundle] = @(_currentSupport);
        if (_currentSupport == MVKAXUnsupported) {
            _fallbackCount++;
            return NO;
        }
    }

    AXUIElementRef focused = copyFocusedElement();
    if (focused == NULL) { _fallbackCount++; return NO; }

    BOOL done = NO;
    CFTypeRef rangeVal = NULL;

    if (AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute, &rangeVal) == kAXErrorSuccess
        && rangeVal != NULL) {

        CFRange caret = {0, 0};
        if (AXValueGetValue((AXValueRef)rangeVal, kAXValueCFRangeType, &caret)
            && caret.location >= (CFIndex)backspaceCount) {

            // Bôi đen đúng số ký tự cần xoá rồi ghi đè - MỘT thao tác nguyên tử.
            // caret.length > 0 nghĩa là đang có vùng bôi đen: thường là gợi ý
            // inline của Chrome/Safari/Spotlight (gõ "thu" -> ô địa chỉ chứa
            // "thuanbui.me" với "anbui.me" bôi đen). Phải xoá kèm, nếu không nó
            // dính lại thành chữ thật -> "thưanbui.me".
            CFRange target = { caret.location - backspaceCount,
                               backspaceCount + caret.length };
            AXValueRef tRange = AXValueCreate(kAXValueCFRangeType, &target);
            if (tRange) {
                if (AXUIElementSetAttributeValue(focused, kAXSelectedTextRangeAttribute, tRange) == kAXErrorSuccess) {
                    if (AXUIElementSetAttributeValue(focused, kAXSelectedTextAttribute,
                                                     (__bridge CFStringRef)newText) == kAXErrorSuccess) {
                        done = YES;
                    }
                }
                CFRelease(tRange);
            }
        }
        CFRelease(rangeVal);
    }

    CFRelease(focused);

    if (done) {
        _successCount++;
    } else {
        // Thất bại lúc chạy thật -> hạ cấp app này, các phím sau đi thẳng đường cũ.
        _currentSupport = MVKAXUnsupported;
        if (_currentBundle.length > 0)
            _supportByBundle[_currentBundle] = @(MVKAXUnsupported);
        _fallbackCount++;
    }
    return done;
}

int MacViKeyAXSuccessCount(void)  { return _successCount; }
int MacViKeyAXFallbackCount(void) { return _fallbackCount; }

NSString* MacViKeyAXCurrentAppSupport(void) {
    if (!_axEnabled) return @"tắt";
    switch (_currentSupport) {
        case MVKAXSupported:   return @"hỗ trợ";
        case MVKAXUnsupported: return @"không hỗ trợ";
        default:               return @"chưa dò";
    }
}
