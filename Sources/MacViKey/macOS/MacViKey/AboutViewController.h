//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  AboutViewController.h
//  MacViKey
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AboutViewController : NSViewController
@property (weak) IBOutlet NSTextField *VersionInfo;
@property (weak) IBOutlet NSButton *CheckNewVersionButton;
@property (weak) IBOutlet NSButton *CheckUpdateOnStatus;

// Cac nhan thong tin duoc do tu Info.plist luc chay (xem MacViKeyInfo).
@property (weak) IBOutlet NSTextField *AppTitle;
@property (weak) IBOutlet NSTextField *HomePageLink;
@property (weak) IBOutlet NSTextField *ReleasesLink;
@property (weak) IBOutlet NSTextField *IssuesLink;
@property (weak) IBOutlet NSTextField *CopyrightInfo;

@end

NS_ASSUME_NONNULL_END
