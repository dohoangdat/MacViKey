//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyManager.m
//  MacViKey
//
//  Modifications copyright © 2026 Do Hoang Dat
//

#import "MJAccessibilityUtils.h"
#import "MacViKeyInfo.h"
#import "MacViKeyManager.h"

extern void MacViKeyInit(void);

extern CGEventRef MacViKeyCallback(CGEventTapProxy proxy,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon);


@interface MacViKeyManager ()

@end

@implementation MacViKeyManager {

}
static BOOL _isInited = NO;

//Tap ban phim: ACTIVE (kCGEventTapOptionDefault) vi phai sua/nuot phim.
static CFMachPortRef      eventTap;
static CFRunLoopSourceRef runLoopSource;

//Tap chuot: CHI NGHE (kCGEventTapOptionListenOnly).
//
//RAT QUAN TRONG. Truoc day chuot nam chung mask voi ban phim trong mot tap
//active duy nhat. Tap active chan luong su kien cua CA phien lam viec cho toi
//khi callback tra ve - nen bat cu truc trac nao cua bo go cung lam DUNG LUON
//CHUOT, va nguoi dung mat not duong cuoi cung de tu cuu minh.
//
//Voi chuot ta chi can BIET la nguoi dung vua bam de dat lai phien go
//(RequestNewSession) - khong sua, khong nuot. Tap chi-nghe lam dung viec do ma
//khong bao gio giu su kien lai.
static CFMachPortRef      mouseTap;
static CFRunLoopSourceRef mouseRunLoopSource;

#pragma mark -MacViKey: khoi phuc event tap

//macOS tu tat event tap khi callback chay qua lau (kCGEventTapDisabledByTimeout)
//hoac khi nguoi dung bam phim qua nhanh luc he thong ban (ByUserInput).
//Neu khong ai bat lai, bo go chet han cho toi khi restart app.
//
//NHUNG: khong duoc bat lai khi da MAT quyen Tro nang. Mot tap active van cam
//dau vao luong su kien ma khong con quyen xu ly la treo ca may.
BOOL MacViKeyReenableEventTap(void) {
    if (eventTap == NULL || !_isInited)
        return NO;
    if (!MJAccessibilityIsEnabled())
        return NO;
    CGEventTapEnable(eventTap, true);
    if (mouseTap != NULL)
        CGEventTapEnable(mouseTap, true);
    return CGEventTapIsEnabled(eventTap);
}

//CGEventTapIsEnabled chi cho biet CO BAT hay khong, KHONG cho biet con quyen
//hay khong. Mat quyen Tro nang thi tap van bao "dang bat" trong khi khong su
//kien nao toi duoc tay ta - nen phai hoi ca TCC, neu khong moi noi goi ham nay
//(giao dien, watchdog) deu bi noi doi.
BOOL MacViKeyIsEventTapAlive(void) {
    return (eventTap != NULL && _isInited && MJAccessibilityIsEnabled() &&
            CGEventTapIsEnabled(eventTap));
}

+(BOOL)isInited {
    return _isInited;
}

+(BOOL)initEventTap {
    if (_isInited)
        return true;
    
    //init modernKey
    MacViKeyInit();
    
    //Khong co quyen thi dung tao tap. Tao duoc mot tap active ma khong xu ly
    //duoc su kien la cach chac chan nhat de treo may.
    if (!MJAccessibilityIsEnabled()) {
        fprintf(stderr, "khong co quyen Tro nang - khong tao event tap\n");
        return NO;
    }

    //Tap ban phim: active, vi phai sua va nuot phim.
    CGEventMask keyMask = ((1 << kCGEventKeyDown) |
                           (1 << kCGEventKeyUp) |
                           (1 << kCGEventFlagsChanged));

    eventTap = CGEventTapCreate(kCGSessionEventTap,
                                kCGHeadInsertEventTap,
                                kCGEventTapOptionDefault,
                                keyMask,
                                MacViKeyCallback,
                                NULL);
    
    if (!eventTap) {
        
        fprintf(stderr, "failed to create event tap\n");
        return NO;
    }
    
    _isInited = YES;
    
    // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
    // Enable the event tap.
    CGEventTapEnable(eventTap, true);

    //Tap chuot: chi nghe. Tao rieng de chuot khong bao gio bi bo go giu lai.
    //Tao that bai cung khong sao - chi mat viec dat lai phien go khi bam chuot,
    //con hon lam hong ca duong ban phim.
    CGEventMask mouseMask = ((1 << kCGEventLeftMouseDown) |
                             (1 << kCGEventRightMouseDown) |
                             (1 << kCGEventLeftMouseDragged) |
                             (1 << kCGEventRightMouseDragged));
    mouseTap = CGEventTapCreate(kCGSessionEventTap,
                                kCGHeadInsertEventTap,
                                kCGEventTapOptionListenOnly,
                                mouseMask,
                                MacViKeyCallback,
                                NULL);
    if (mouseTap) {
        mouseRunLoopSource =
            CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), mouseRunLoopSource,
                           kCFRunLoopCommonModes);
        CGEventTapEnable(mouseTap, true);
    } else {
        fprintf(stderr, "khong tao duoc tap chuot (chi-nghe)\n");
    }
    
    return YES;
}

+(BOOL)stopEventTap {
    if (_isInited) { //release all object
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        runLoopSource = nil;
        
        CFMachPortInvalidate(eventTap);
        CFRelease(eventTap);
        eventTap = NULL;

        if (mouseTap != NULL) {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), mouseRunLoopSource,
                                  kCFRunLoopCommonModes);
            CFRelease(mouseRunLoopSource);
            mouseRunLoopSource = nil;

            CFMachPortInvalidate(mouseTap);
            CFRelease(mouseTap);
            mouseTap = NULL;
        }
        
        _isInited = false;
    }
    return YES;
}

+(NSArray*)getTableCodes {
    return [[NSArray alloc] initWithObjects:
            @"Unicode",
            @"TCVN3 (ABC)",
            @"VNI Windows",
            @"Unicode tổ hợp",
            @"Vietnamese Locale CP 1258", nil];
}

+(NSString*)getBuildDate {
    return [NSString stringWithUTF8String:__DATE__];
}

+(void)showMessage:(NSWindow*)window message:(NSString*)msg subMsg:(NSString*)subMsg {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:msg];
    [alert setInformativeText:subMsg];
    [alert addButtonWithTitle:@"OK"];
    if (window) {
        [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        }];
    } else {
        [alert runModal];
    }
}

#pragma mark -AutoUpdate feature

// Kiem tra ban moi.
//
// callback != nil nghia la NGUOI DUNG tu bam kiem tra. Khi do moi ket qua deu
// phai bao ra - ke ca "dang dung ban moi nhat" va ke ca khi that bai. Bam mot
// muc menu roi khong thay gi la nguoi dung tuong app treo.
// callback == nil la kiem tra nen: chi len tieng khi that co ban moi.
+(void)checkNewVersion:(NSWindow*)parent callbackFunc:(CheckNewVersionCallback) callback {
    BOOL userInitiated = (callback != nil);

    void (^finish)(void) = ^{
        if (callback != nil)
            callback();
    };
    void (^fail)(NSString*) = ^(NSString* detail) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finish();
            if (userInitiated)
                [self showMessage:parent
                          message:@"Không kiểm tra được bản mới"
                           subMsg:detail];
        });
    };

    // versionCheckURL doc tu Info.plist (MVKVersionCheckURL). Thieu key do la
    // nil, ma dataTaskWithURL:nil nem NSInvalidArgumentException -> bam muc
    // menu la crash. Phai chan truoc khi goi.
    NSURL* url = MacViKeyInfo.versionCheckURL;
    if (url == nil) {
        fail(@"Bản này không cấu hình địa chỉ kiểm tra phiên bản. "
             @"Xem trang phát hành trên GitHub.");
        return;
    }

    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            fail(@"Không kết nối được. Kiểm tra lại mạng rồi thử lần nữa.");
            return;
        }
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]]
                               ? ((NSHTTPURLResponse *)response).statusCode : 0;
        if (status != 200 || data == nil) {
            fail([NSString stringWithFormat:@"Máy chủ trả về lỗi (%ld).", (long)status]);
            return;
        }

        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSDictionary *ver = [object isKindOfClass:[NSDictionary class]]
                                ? [object valueForKey:@"latestVersion"] : nil;
        if (![ver isKindOfClass:[NSDictionary class]]) {
            fail(@"Dữ liệu phiên bản không đọc được.");
            return;
        }

        int versionCode = [[ver valueForKey:@"versionCode"] intValue];
        int currentVersionCode = (int)[((NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]) integerValue];
        BOOL needUpdating = versionCode > currentVersionCode;

        dispatch_async(dispatch_get_main_queue(), ^{
            finish();
            if (needUpdating || userInitiated) {
                [self showUpdateMessage:parent
                           needUpdating:needUpdating
                             newVersion:[[ver valueForKey:@"versionName"] description]];
            }
        });
    }] resume];
}

+(void)showUpdateMessage:(NSWindow*)parent needUpdating:(BOOL)needUpdating newVersion:(NSString*)versionString {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:(needUpdating ? [NSString stringWithFormat:@"%@ có phiên bản mới (%@)", MacViKeyInfo.appName, versionString] : @"Bạn đang dùng phiên bản mới nhất!")];
    [alert setInformativeText:(needUpdating ? @"Bấm 'Có' để mở trang tải bản mới." : @"")];
    
    if (!needUpdating) {
        [alert addButtonWithTitle:@"OK"];
    } else {
        [alert addButtonWithTitle:@"Có"];
        [alert addButtonWithTitle:@"Không"];
    }
    if (parent == nil) {
        [alert.window makeKeyAndOrderFront:nil];
        [alert.window setLevel:NSStatusWindowLevel];
        NSModalResponse res = [alert runModal];
        if (res == 1000 && needUpdating) {
            [self launchUpdateHelper];
        }
    } else {
        [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == 1000 && needUpdating) {
                [self launchUpdateHelper];
            }
        }];
    }
}

//MacViKey: du an goc sao chep va chay mot app cap nhat rieng tu Contents/Library/LoginItems.
//Target do da duoc go bo, nen thay bang cach mo thang trang releases - don gian,
//khong co trinh cap nhat rieng de bao tri va khong tu thoat app.
+(void)launchUpdateHelper {
    [MacViKeyInfo openURL:MacViKeyInfo.releasesURL];
}

+(NSString*)getApplicationSupportFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    return [NSString stringWithFormat:@"%@/MacViKey", applicationSupportDirectory];
}

@end
