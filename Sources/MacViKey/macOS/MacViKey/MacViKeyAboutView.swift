//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyAboutView.swift
//  MacViKey — hai trang thông tin trong cửa sổ Cài đặt
//
//  Ủng hộ đứng riêng vì đó là trang duy nhất xin người dùng điều gì đó; Giới
//  thiệu gom cả danh sách liên kết, vì mở trang chủ hay kho mã nguồn đều là
//  "tìm hiểu thêm về phần mềm này".
//
//  Mọi chuỗi vẫn đọc từ Info.plist qua MacViKeyInfo, không hard-code lại.
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

import SwiftUI

/// Khung chung cho hai trang thông tin: cùng lề, cùng bề rộng, cùng kiểu cuộn.
private struct InfoPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.sectionSpacing) {
                content
                Spacer(minLength: 0)
            }
            .padding(Design.pagePadding)
            .frame(width: Design.detailWidth, alignment: .leading)
        }
    }
}

// MARK: - Giới thiệu

struct MacViKeyAboutPage: View {
    var body: some View {
        InfoPage {
            HStack(alignment: .center, spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(MacViKeyInfo.appName)
                        .font(.system(size: 22, weight: .semibold))
                    Text(MacViKeyInfo.versionInfoText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Text(MacViKeyInfo.aboutText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Design.tightSpacing) {
                SectionHeader(title: MacViKeyMenuLayout.string(
                    "settings.links.title", fallback: "Liên kết"))
                Card(spacing: 9) {
                    LinkRow(label: MacViKeyMenuLayout.string("settings.links.home",
                                                             fallback: "Trang chủ"),
                            url: MacViKeyInfo.homePageURL)
                    LinkRow(label: MacViKeyMenuLayout.string("settings.links.releases",
                                                             fallback: "Bản phát hành"),
                            url: MacViKeyInfo.releasesURL)
                    LinkRow(label: MacViKeyMenuLayout.string("settings.links.source",
                                                             fallback: "Mã nguồn"),
                            url: MacViKeyInfo.sourceCodeURL)
                    LinkRow(label: MacViKeyMenuLayout.string("settings.links.issues",
                                                             fallback: "Góp ý / báo lỗi"),
                            url: MacViKeyInfo.issuesURL)
                    LinkRow(label: MacViKeyMenuLayout.string("settings.links.email",
                                                             fallback: "Email tác giả"),
                            url: MacViKeyInfo.authorMailtoURL)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Divider()
                Text(MacViKeyInfo.copyrightShort)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("Giấy phép")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Button {
                        MacViKeyInfo.open(MacViKeyInfo.licenseURL)
                    } label: {
                        Text(MacViKeyInfo.licenseName)
                            .font(.system(size: 11))
                            .underline()
                    }
                    .buttonStyle(LinkButtonStyle())
                }
            }
        }
    }
}

// MARK: - Ủng hộ

struct MacViKeyDonatePage: View {
    var body: some View {
        InfoPage {
            PageTitle(title: MacViKeyMenuLayout.string("settings.donate.title",
                                                      fallback: "Ủng hộ MacViKey"),
                      subtitle: nil)

            Card {
                // Trái tim đặt cạnh lời kêu gọi để trang không chỉ là một khối
                // chữ; đây là trang duy nhất xin người dùng điều gì đó.
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Design.danger)
                    Text(MacViKeyInfo.donateText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let url = MacViKeyInfo.donateURL {
                    Button {
                        MacViKeyInfo.open(url)
                    } label: {
                        Text(MacViKeyMenuLayout.string("settings.donate.button",
                                                       fallback: "Mở hòm công đức"))
                    }
                    .mvkHelp(url.absoluteString)
                }
            }
        }
    }
}
