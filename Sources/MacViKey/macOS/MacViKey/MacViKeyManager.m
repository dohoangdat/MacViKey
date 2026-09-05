//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyManager.m
//  MacViKey
//
//  Modifications copyright © 2026 Do Hoang Dat
//

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

static CFMachPortRef      eventTap;
static CGEventMask        eventMask;
static CFRunLoopSourceRef runLoopSource;

#pragma mark -MacViKey: khoi phuc event tap

//macOS tu tat event tap khi callback chay qua lau (kCGEventTapDisabledByTimeout)
//hoac khi nguoi dung bam phim qua nhanh luc he thong ban (ByUserInput).
//Neu khong ai bat lai, bo go chet han cho toi khi restart app.
BOOL MacViKeyReenableEventTap(void) {
    if (eventTap == NULL || !_isInited)
        return NO;
    CGEventTapEnable(eventTap, true);
    return CGEventTapIsEnabled(eventTap);
}

BOOL MacViKeyIsEventTapAlive(void) {
    return (eventTap != NULL && _isInited && CGEventTapIsEnabled(eventTap));
}

+(BOOL)isInited {
    return _isInited;
}

+(BOOL)initEventTap {
    if (_isInited)
        return true;
    
    //init modernKey
    MacViKeyInit();
    
    // Create an event tap. We are interested in key presses.
    eventMask = ((1 << kCGEventKeyDown) |
                 (1 << kCGEventKeyUp) |
                 (1 << kCGEventFlagsChanged) |
                 (1 << kCGEventLeftMouseDown) |
                 (1 << kCGEventRightMouseDown) |
                 (1 << kCGEventLeftMouseDragged) |
                 (1 << kCGEventRightMouseDragged));
    
    eventTap = CGEventTapCreate(kCGSessionEventTap,
                                kCGHeadInsertEventTap,
                                0,
                                eventMask,
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

#pragma mark -AutoUpdate feature

+(void)checkNewVersion:(NSWindow*)parent callbackFunc:(CheckNewVersionCallback) callback {
    //load new version config
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:MacViKeyInfo.versionCheckURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data) {
                if(NSClassFromString(@"NSJSONSerialization")) {
                    NSError *error = nil;
                    id object = [NSJSONSerialization
                                 JSONObjectWithData:data
                                 options:0
                                 error:&error];
                    
                    if(error) {  }
                    if([object isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *results = object;
                        NSDictionary *ver = [results valueForKey:@"latestVersion"];
                        NSString* versionCodeString = [ver valueForKey:@"versionCode"];
                        int versionCode = (int)[versionCodeString integerValue];
                        int currentVersionCode = (int)[((NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]) integerValue];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (callback != nil) {
                                callback();
                            }
                            if (versionCode > currentVersionCode || callback != nil) {
                                [self showUpdateMessage:parent needUpdating:versionCode > currentVersionCode newVersion:[ver valueForKey:@"versionName"]];
                            }
                        });
                    }
                    else {
                        //oh my god
                    }
                }
                else {
                    //can not parse json
                }
            }
        }
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
