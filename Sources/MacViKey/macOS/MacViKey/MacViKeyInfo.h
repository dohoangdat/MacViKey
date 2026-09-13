//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyInfo.h
//  MacViKey — nguồn dữ liệu duy nhất cho thông tin tác giả / liên hệ / liên kết
//
//  Mọi chuỗi về tác giả, email, website, kho mã nguồn, bản quyền... đều được
//  khai báo MỘT CHỖ trong Info.plist (các khoá MVK*) và đọc lại qua lớp này.
//  Không hard-code lại các chuỗi đó ở bất kỳ file nào khác.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Khoá tương ứng trong Info.plist.
extern NSString *const MacViKeyInfoKeyAuthorName;      // MVKAuthorName
extern NSString *const MacViKeyInfoKeyAuthorEmail;     // MVKAuthorEmail
extern NSString *const MacViKeyInfoKeyCopyrightShort;  // MVKCopyrightShort
extern NSString *const MacViKeyInfoKeyLicenseName;     // MVKLicenseName
extern NSString *const MacViKeyInfoKeyLicenseURL;      // MVKLicenseURL
extern NSString *const MacViKeyInfoKeyHomePageURL;     // MVKHomePageURL
extern NSString *const MacViKeyInfoKeySourceCodeURL;   // MVKSourceCodeURL
extern NSString *const MacViKeyInfoKeyIssuesURL;       // MVKIssuesURL
extern NSString *const MacViKeyInfoKeyFeedbackURL;     // MVKFeedbackURL
extern NSString *const MacViKeyInfoKeyReleasesURL;     // MVKReleasesURL
extern NSString *const MacViKeyInfoKeyVersionCheckURL; // MVKVersionCheckURL
extern NSString *const MacViKeyInfoKeyChangelogURL;    // MVKChangelogURL
extern NSString *const MacViKeyInfoKeyUpstreamName;    // MVKUpstreamName
extern NSString *const MacViKeyInfoKeyUpstreamURL;     // MVKUpstreamURL
extern NSString *const MacViKeyInfoKeyAboutText;       // MVKAboutText
extern NSString *const MacViKeyInfoKeyDonateURL;       // MVKDonateURL
extern NSString *const MacViKeyInfoKeyDonateText;      // MVKDonateText

@interface MacViKeyInfo : NSObject

/// Đọc thô một khoá bất kỳ trong Info.plist (trả về @"" nếu thiếu).
+ (NSString *)stringForKey:(NSString *)key;
/// Như trên nhưng trả về NSURL (nil nếu thiếu hoặc không hợp lệ).
+ (nullable NSURL *)URLForKey:(NSString *)key;

#pragma mark - Nhận dạng ứng dụng

@property(class, readonly) NSString *appName;         // CFBundleDisplayName
@property(class, readonly) NSString *versionString;   // CFBundleShortVersionString
@property(class, readonly) NSString *buildString;     // CFBundleVersion
/// "Phiên bản 1.0 (build 1) - Ngày cập nhật ..."
@property(class, readonly) NSString *versionInfoText;
/// Ngay bien dich ban dang chay, rieng ra de trang Gioi thieu khong phai mang.
@property(class, readonly) NSString *buildDateText;

#pragma mark - Tác giả & bản quyền

@property(class, readonly) NSString *authorName;
@property(class, readonly) NSString *authorEmail;
@property(class, readonly) NSString *copyrightShort;   // "Đỗ Hoàng Đạt © 2026"
@property(class, readonly) NSString *copyrightFull;    // NSHumanReadableCopyright
@property(class, readonly) NSString *licenseName;
@property(class, readonly) NSString *aboutText;
/// Loi keu goi ung ho hien trong khung Donate.
@property(class, readonly) NSString *donateText;
@property(class, readonly) NSString *upstreamName;

#pragma mark - Liên kết

@property(class, readonly, nullable) NSURL *homePageURL;
@property(class, readonly, nullable) NSURL *sourceCodeURL;
@property(class, readonly, nullable) NSURL *issuesURL;
/// Noi gop y / de xuat tinh nang - tach khoi issuesURL (noi bao loi).
@property(class, readonly, nullable) NSURL *feedbackURL;
@property(class, readonly, nullable) NSURL *releasesURL;
@property(class, readonly, nullable) NSURL *versionCheckURL;
/// Lich su cap nhat (CHANGELOG tren GitHub).
@property(class, readonly, nullable) NSURL *changelogURL;
@property(class, readonly, nullable) NSURL *licenseURL;
@property(class, readonly, nullable) NSURL *upstreamURL;
/// Hom cong duc (sao ke ten nguoi ung ho).
@property(class, readonly, nullable) NSURL *donateURL;
/// mailto: dựng từ authorEmail.
@property(class, readonly, nullable) NSURL *authorMailtoURL;

/// Mở một liên kết trong trình duyệt mặc định (bỏ qua nếu url nil).
+ (void)openURL:(nullable NSURL *)url;

@end

NS_ASSUME_NONNULL_END
