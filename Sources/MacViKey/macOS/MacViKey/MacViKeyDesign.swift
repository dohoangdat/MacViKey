//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyDesign.swift
//  MacViKey — các hằng số và thành phần dùng chung của lớp giao diện SwiftUI
//
//  Một chỗ duy nhất định nghĩa khoảng thở, cỡ chữ và màu. Hai cửa sổ (Giới
//  thiệu, bảng nhanh) đọc chung từ đây nên không thể lệch nhau.
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

enum Design {
    /// Bề rộng cố định của cả hai cửa sổ. Cửa sổ hẹp và cao đọc dễ hơn cửa sổ
    /// vuông: mắt không phải quét ngang.
    static let windowWidth: CGFloat = 360

    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 18
    static let rowSpacing: CGFloat = 10
    static let tightSpacing: CGFloat = 6

    static let cornerRadius: CGFloat = 10
}

/// Tiêu đề của một nhóm: chữ nhỏ, in hoa, màu nhạt. Nhóm được nhận ra bằng
/// tương phản chữ chứ không bằng đường kẻ - ít nét vẽ thì bảng đỡ rối.
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
    }
}

/// Khung nền cho một nhóm nội dung.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous)
                .strokeBorder(Color(.separatorColor), lineWidth: 1)
        )
    }
}

/// Một dòng liên kết: nhãn bên trái, địa chỉ bấm được bên phải.
struct LinkRow: View {
    let label: String
    let url: URL?

    var body: some View {
        if let url {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer(minLength: 8)
                Button {
                    MacViKeyInfo.open(url)
                } label: {
                    Text(url.host ?? url.absoluteString)
                        .underline()
                }
                .buttonStyle(LinkButtonStyle())
                .mvkHelp(url.absoluteString)
            }
            .font(.system(size: 12))
        }
    }
}

// MARK: - Tuong thich phien ban

extension View {
    /// `.help()` (bong huong dan khi re chuot) chi co tu macOS 11.
    ///
    /// MenuLayout.json co truong "hint" cho tung muc va README coi bong huong
    /// dan la mot tinh nang, nen khong the bo han. Tren 10.15 thi khong co
    /// tooltip - do la gioi han cua SwiftUI ban dau, khong phai lua chon.
    @ViewBuilder
    func mvkHelp(_ text: String?) -> some View {
        if let text = text, !text.isEmpty, #available(macOS 11.0, *) {
            self.help(text)
        } else {
            self
        }
    }
}
