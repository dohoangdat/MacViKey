//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  AboutViewController.m
//  MacViKey
//

#import "AboutViewController.h"
#import "MacViKeyInfo.h"
#import "MacViKeyManager.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.VersionInfo.stringValue = MacViKeyInfo.versionInfoText;
    [self macViKeyFillContactInfo];
    
    NSInteger dontCheckUpdate = [[NSUserDefaults standardUserDefaults] integerForKey:@"DontCheckUpdate"];
    self.CheckUpdateOnStatus.state = dontCheckUpdate ? NSControlStateValueOff :NSControlStateValueOn;
}

/// Do moi nhan lien he tu Info.plist (xem MacViKeyInfo) thay vi chuoi trong storyboard.
- (void)macViKeyFillContactInfo {
    self.AppTitle.stringValue = MacViKeyInfo.appName;
    self.HomePageLink.stringValue = MacViKeyInfo.homePageURL.absoluteString ?: @"";
    self.ReleasesLink.stringValue = MacViKeyInfo.releasesURL.absoluteString ?: @"";
    self.IssuesLink.stringValue = MacViKeyInfo.issuesURL.absoluteString ?: @"";
    self.CopyrightInfo.stringValue = MacViKeyInfo.copyrightShort;
    self.DonateBody.stringValue = MacViKeyInfo.donateText;
    self.DonateLink.stringValue = MacViKeyInfo.donateURL.absoluteString ?: @"";
}

- (IBAction)onHomePage:(id)sender {
    [MacViKeyInfo openURL:MacViKeyInfo.homePageURL];
}

- (IBAction)onFanPage:(id)sender {
    [MacViKeyInfo openURL:MacViKeyInfo.issuesURL];
}

- (IBAction)onLatestReleaseVersion:(id)sender {
    [MacViKeyInfo openURL:MacViKeyInfo.releasesURL];
}

- (IBAction)onDonate:(id)sender {
    [MacViKeyInfo openURL:MacViKeyInfo.donateURL];
}

- (IBAction)onCheckUpdateOnStartup:(NSButton *)sender {
    NSInteger val = sender.state == NSControlStateValueOn ? 0 : 1;
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"DontCheckUpdate"];
}

- (IBAction)onCheckNewVersion:(id)sender {
    
    self.CheckNewVersionButton.title = @"Đang kiểm tra...";
    self.CheckNewVersionButton.enabled = false;
    
    [MacViKeyManager checkNewVersion: self.view.window callbackFunc:^{
        self.CheckNewVersionButton.enabled = true;
        self.CheckNewVersionButton.title = @"Kiểm tra bản mới...";
    }];
}

@end
