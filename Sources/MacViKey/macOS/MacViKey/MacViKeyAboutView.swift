//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyAboutView.swift
//  MacViKey — cửa sổ Giới thiệu, viết bằng SwiftUI
//
//  Thay cho AboutViewController + scene "AboutWindow" trong Main.storyboard.
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

struct MacViKeyAboutView: View {
    /// Nhãn nút kiểm tra bản mới đổi theo trạng thái, nên phải là state.
    @State private var checking = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            header
            Text(MacViKeyInfo.aboutText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            links
            donate
            footer
        }
        .padding(Design.pagePadding)
        .frame(width: Design.windowWidth)
    }

    // MARK: - Đầu trang: logo, tên, phiên bản

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            appIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(MacViKeyInfo.appName)
                    .font(.system(size: 20, weight: .semibold))
                Text(MacViKeyInfo.versionInfoText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                checkButton
                    .padding(.top, 6)
            }
        }
    }

    private var appIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 56, height: 56)
    }

    private var checkButton: some View {
        Button {
            checking = true
            MacViKeyManager.checkNewVersion(nil) {
                checking = false
            }
        } label: {
            Text(checking ? "Đang kiểm tra..." : "Kiểm tra bản mới")
        }
        .disabled(checking)
    }

    // MARK: - Liên kết

    private var links: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: "Liên kết")
            Card {
                LinkRow(label: "Trang chủ", url: MacViKeyInfo.homePageURL)
                LinkRow(label: "Bản phát hành", url: MacViKeyInfo.releasesURL)
                LinkRow(label: "Mã nguồn", url: MacViKeyInfo.sourceCodeURL)
                LinkRow(label: "Góp ý / báo lỗi", url: MacViKeyInfo.issuesURL)
            }
        }
    }

    // MARK: - Ủng hộ / hòm công đức

    private var donate: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: "Ủng hộ")
            Card {
                Text(MacViKeyInfo.donateText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = MacViKeyInfo.donateURL {
                    Button {
                        MacViKeyInfo.open(url)
                    } label: {
                        Text("Mở hòm công đức")
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Chân trang: bản quyền, giấy phép

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
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
