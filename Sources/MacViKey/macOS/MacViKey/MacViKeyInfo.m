//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyInfo.m
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

#import "MacViKeyInfo.h"
#import <AppKit/AppKit.h>

NSString *const MacViKeyInfoKeyAuthorName = @"MVKAuthorName";
NSString *const MacViKeyInfoKeyAuthorEmail = @"MVKAuthorEmail";
NSString *const MacViKeyInfoKeyCopyrightShort = @"MVKCopyrightShort";
NSString *const MacViKeyInfoKeyLicenseName = @"MVKLicenseName";
NSString *const MacViKeyInfoKeyLicenseURL = @"MVKLicenseURL";
NSString *const MacViKeyInfoKeyHomePageURL = @"MVKHomePageURL";
NSString *const MacViKeyInfoKeySourceCodeURL = @"MVKSourceCodeURL";
NSString *const MacViKeyInfoKeyIssuesURL = @"MVKIssuesURL";
NSString *const MacViKeyInfoKeyReleasesURL = @"MVKReleasesURL";
NSString *const MacViKeyInfoKeyVersionCheckURL = @"MVKVersionCheckURL";
NSString *const MacViKeyInfoKeyUpstreamName = @"MVKUpstreamName";
NSString *const MacViKeyInfoKeyUpstreamURL = @"MVKUpstreamURL";
NSString *const MacViKeyInfoKeyAboutText = @"MVKAboutText";
NSString *const MacViKeyInfoKeyDonateURL = @"MVKDonateURL";
NSString *const MacViKeyInfoKeyDonateText = @"MVKDonateText";

@implementation MacViKeyInfo

+ (NSString *)stringForKey:(NSString *)key {
  id value = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
  return [value isKindOfClass:[NSString class]] ? (NSString *)value : @"";
}

+ (NSURL *)URLForKey:(NSString *)key {
  NSString *value = [self stringForKey:key];
  return value.length ? [NSURL URLWithString:value] : nil;
}

#pragma mark - Nhan dang ung dung

+ (NSString *)appName {
  NSString *name = [self stringForKey:@"CFBundleDisplayName"];
  return name.length ? name : @"MacViKey";
}

+ (NSString *)versionString {
  return [self stringForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)buildString {
  return [self stringForKey:@"CFBundleVersion"];
}

+ (NSString *)versionInfoText {
  return [NSString stringWithFormat:@"Phiên bản %@ (build %@) - Ngày cập nhật %@",
                                    self.versionString, self.buildString,
                                    [NSString stringWithUTF8String:__DATE__]];
}

#pragma mark - Tac gia & ban quyen

+ (NSString *)authorName {
  return [self stringForKey:MacViKeyInfoKeyAuthorName];
}

+ (NSString *)authorEmail {
  return [self stringForKey:MacViKeyInfoKeyAuthorEmail];
}

+ (NSString *)copyrightShort {
  return [self stringForKey:MacViKeyInfoKeyCopyrightShort];
}

+ (NSString *)copyrightFull {
  return [self stringForKey:@"NSHumanReadableCopyright"];
}

+ (NSString *)licenseName {
  return [self stringForKey:MacViKeyInfoKeyLicenseName];
}

+ (NSString *)aboutText {
  return [self stringForKey:MacViKeyInfoKeyAboutText];
}

+ (NSString *)donateText {
  return [self stringForKey:MacViKeyInfoKeyDonateText];
}

+ (NSString *)upstreamName {
  return [self stringForKey:MacViKeyInfoKeyUpstreamName];
}

#pragma mark - Lien ket

+ (NSURL *)homePageURL {
  return [self URLForKey:MacViKeyInfoKeyHomePageURL];
}

+ (NSURL *)sourceCodeURL {
  return [self URLForKey:MacViKeyInfoKeySourceCodeURL];
}

+ (NSURL *)issuesURL {
  return [self URLForKey:MacViKeyInfoKeyIssuesURL];
}

+ (NSURL *)releasesURL {
  return [self URLForKey:MacViKeyInfoKeyReleasesURL];
}

+ (NSURL *)versionCheckURL {
  return [self URLForKey:MacViKeyInfoKeyVersionCheckURL];
}

+ (NSURL *)licenseURL {
  return [self URLForKey:MacViKeyInfoKeyLicenseURL];
}

+ (NSURL *)upstreamURL {
  return [self URLForKey:MacViKeyInfoKeyUpstreamURL];
}

+ (NSURL *)donateURL {
  return [self URLForKey:MacViKeyInfoKeyDonateURL];
}

+ (NSURL *)authorMailtoURL {
  NSString *email = self.authorEmail;
  return email.length
             ? [NSURL URLWithString:[@"mailto:" stringByAppendingString:email]]
             : nil;
}

+ (void)openURL:(NSURL *)url {
  if (url) {
    [[NSWorkspace sharedWorkspace] openURL:url];
  }
}

@end
