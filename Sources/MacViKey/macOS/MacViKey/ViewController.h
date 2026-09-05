//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  ViewController.h
//  MacViKey
//

#import <Cocoa/Cocoa.h>
#import "MyTextField.h"

@interface ViewController : NSViewController<MyTextFieldDelegate>
@property (strong) IBOutlet NSView *viewParent;
@property (weak) IBOutlet NSButton *tabbuttonInfo;
@property (weak) IBOutlet NSBox *tabviewInfo;

@property (weak) IBOutlet NSPopUpButton *popupInputType;
@property (weak) IBOutlet NSPopUpButton *popupCode;

@property (weak) IBOutlet NSBox *appOK;
@property (weak) IBOutlet NSBox *permissionWarning;
@property (weak) IBOutlet NSButton *retryButton;

@property (weak) IBOutlet NSButton *VietButton;
@property (weak) IBOutlet NSButton *EngButton;

@property (weak) IBOutlet NSButton *FreeMarkButton;

@property (weak) IBOutlet NSTextField *VersionInfo;

// Cac nhan thong tin/lien he duoc do tu Info.plist luc chay (xem MacViKeyInfo).
@property (weak) IBOutlet NSTextField *HomePageLink;
@property (weak) IBOutlet NSTextField *IssuesLink;
@property (weak) IBOutlet NSTextField *EmailLink;
@property (weak) IBOutlet NSTextField *CopyrightInfo;
@property (weak) IBOutlet NSTextField *AboutText;

-(void)fillData;
@end

