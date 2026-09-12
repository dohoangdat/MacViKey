//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  AppDelegate.h
//  MacViKey
//
//  Modifications copyright © 2026 Do Hoang Dat
//

#import <Cocoa/Cocoa.h>

#define MACVIKEY_BUNDLE @"com.mac.vi.key"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

-(void)onImputMethodChanged:(BOOL)willNotify;
-(void)onInputMethodSelected;

-(void)askPermission;

-(void)onInputTypeSelectedIndex:(int)index;
-(void)onCodeTableChanged:(int)index;

-(void)setRunOnStartup:(BOOL)val;
-(void)loadDefaultConfig;

-(void)setGrayIcon:(BOOL)val;


-(void)showIconOnDock:(BOOL)val;
@end

