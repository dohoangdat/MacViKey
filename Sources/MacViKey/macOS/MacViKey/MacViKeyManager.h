//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyManager.h
//  MacViKey
//

#ifndef MacViKeyManager_h
#define MacViKeyManager_h

#import <Cocoa/Cocoa.h>

typedef void (^CheckNewVersionCallback)(void);

@interface MacViKeyManager : NSObject
+(BOOL)isInited;
+(BOOL)initEventTap;
+(BOOL)stopEventTap;

+(NSArray*)getTableCodes;

+(NSString*)getBuildDate;
+(void)showMessage:(NSWindow*)window message:(NSString*)msg subMsg:(NSString*)subMsg;


+(void)checkNewVersion:(NSWindow*)parent callbackFunc:(CheckNewVersionCallback) callback;
@end

#endif /* MacViKeyManager_h */
