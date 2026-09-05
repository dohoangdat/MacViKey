//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  AppDelegate.h
//  MacViKey
//
//  Modifications copyright © 2026 Do Hoang Dat
//

#import <Cocoa/Cocoa.h>
#import "ViewController.h"

#define MACVIKEY_BUNDLE @"com.macvikey.app"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

-(void)onImputMethodChanged:(BOOL)willNotify;
-(void)onInputMethodSelected;

-(void)askPermission;

-(void)onInputTypeSelectedIndex:(int)index;
-(void)onCodeTableChanged:(int)index;

-(void)setRunOnStartup:(BOOL)val;
-(void)loadDefaultConfig;

-(void)setGrayIcon:(BOOL)val;

-(void)onMacroSelected;
-(void)onQuickConvert;
-(void)setQuickConvertString;

-(void)showIconOnDock:(BOOL)val;
@end

