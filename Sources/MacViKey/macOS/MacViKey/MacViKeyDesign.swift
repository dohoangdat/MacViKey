//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyDesign.swift
//  MacViKey — hằng số và thành phần dùng chung của lớp giao diện SwiftUI
//
//  Một chỗ duy nhất định nghĩa khoảng thở, cỡ chữ và màu. Mọi trang trong cửa
//  sổ Cài đặt đọc chung từ đây nên không thể lệch nhau.
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
    /// Cửa sổ Cài đặt: thanh bên hẹp, vùng nội dung đủ rộng cho một dòng chữ
    /// dài mà không phải xuống hàng giữa câu.
    static let sidebarWidth: CGFloat = 178
    static let detailWidth: CGFloat = 442
    static let windowHeight: CGFloat = 468

    static let pagePadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 22
    static let rowSpacing: CGFloat = 14
    static let tightSpacing: CGFloat = 7

    static let cornerRadius: CGFloat = 8

    /// Màu đỏ cho hành động phá huỷ. Không dùng `.red` thuần vì nó chói trên
    /// nền sáng của macOS.
    static let danger = Color(red: 0.78, green: 0.22, blue: 0.18)
}

// MARK: - Khối nội dung

/// Tiêu đề của một nhóm trong trang: chữ nhỏ, in hoa, màu nhạt. Nhóm được nhận
/// ra bằng tương phản chữ chứ không bằng đường kẻ - ít nét vẽ thì trang đỡ rối.
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
    }
}

/// Khung nền cho một nhóm nội dung, có viền mảnh và nền nhạt.
struct Card<Content: View>: View {
    var spacing: CGFloat = Design.rowSpacing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
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

/// Đầu mỗi trang: tên trang cỡ lớn, kèm câu dẫn nếu có.
struct PageTitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Một dòng liên kết: nhãn bên trái, địa chỉ bấm được bên phải.
struct LinkRow: View {
    let label: String
    let url: URL?

    var body: some View {
        if let url = url {
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

/// Đèn tròn báo trạng thái. Thấy ngay sống hay chết, không phải đọc chữ.
struct StatusDot: View {
    let on: Bool

    var body: some View {
        Circle()
            .fill(on ? Color.green : Color.orange)
            .frame(width: 9, height: 9)
            .overlay(
                Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
            )
    }
}

// MARK: - Tương thích phiên bản

extension View {
    /// Bóng hướng dẫn khi rê chuột, lấy từ trường "hint" trong MenuLayout.json.
    ///
    /// Gọi qua một modifier riêng chứ không gọi `.help()` trực tiếp vì hint là
    /// tuỳ chọn: xoá "hint" khỏi JSON là không hiện nữa, và ở đây phải coi
    /// chuỗi rỗng y như không có - `.help("")` vẫn vẽ một bóng trống.
    @ViewBuilder
    func mvkHelp(_ text: String?) -> some View {
        if let text = text, !text.isEmpty {
            self.help(text)
        } else {
            self
        }
    }
}
