//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyQuickPanelView.swift
//  MacViKey — bảng nhanh: bản cửa sổ của menu trên thanh trạng thái
//
//  Dữ liệu do phía Objective-C dựng (xem MacViKeyQuickRow.h): nó đi cây
//  MenuLayout.json với đúng bộ lọc mà menu dùng, rồi trả ra danh sách dòng
//  phẳng. Ở đây chỉ vẽ và gọi ngược lại - không có luật nghiệp vụ nào.
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

/// Cầu nối trạng thái. Bảng nhanh phải khớp với prefs mọi lúc, mà prefs bị đổi
/// từ nhiều nơi (menu, phím tắt, engine). Nên không giữ bản sao trạng thái nào:
/// mỗi lần `refresh()` là hỏi lại Objective-C toàn bộ danh sách dòng.
final class QuickPanelModel: ObservableObject {
    @Published var rows: [MacViKeyQuickRow] = []
    @Published var statusTitle: String = ""

    private weak var actions: (any MacViKeyQuickPanelActions)?

    init(actions: any MacViKeyQuickPanelActions) {
        self.actions = actions
        refresh()
    }

    func refresh() {
        guard let actions else { return }
        rows = actions.quickPanelRows()
        statusTitle = actions.quickPanelStatusTitle()
    }

    func toggle(_ row: MacViKeyQuickRow) {
        actions?.quickPanelDidToggleOption(withTag: row.tag)
        refresh()
    }

    func selectSwitchKey(_ row: MacViKeyQuickRow) {
        actions?.quickPanelDidSelectSwitchKey(at: row.tag)
        refresh()
    }

    func tapStatusLine() {
        actions?.quickPanelDidTapStatusLine()
        refresh()
    }

    func tapAction(_ row: MacViKeyQuickRow) {
        actions?.quickPanelDidTapAction(withId: row.rowId)
        refresh()
    }
}

struct MacViKeyQuickPanelView: View {
    @ObservedObject var model: QuickPanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            ForEach(Array(model.rows.enumerated()), id: \.offset) { _, row in
                rowView(row)
            }
        }
        .padding(Design.pagePadding)
        .frame(width: Design.windowWidth)
    }

    // MARK: - Vẽ một dòng
    //
    // rowView và childView KHÔNG gọi lẫn nhau: mỗi dạng dòng có một hàm lá
    // riêng. Hai hàm gọi vòng mà cùng trả `some View` thì kiểu opaque được suy
    // ra bằng chính nó - Swift từ chối biên dịch.

    @ViewBuilder
    private func rowView(_ row: MacViKeyQuickRow) -> some View {
        switch row.kind {
        case .separator:
            Divider()
        case .group:
            groupView(row)
        case .status:
            statusButton
        case .fixedInfo:
            fixedInfoView(row)
        case .toggle:
            toggleView(row)
        case .radio:
            radioView(row)
        case .action:
            actionButton(row)
        @unknown default:
            EmptyView()
        }
    }

    /// Dòng nằm trong một nhóm. Nhóm không chứa nhóm con nên không cần đệ quy.
    @ViewBuilder
    private func childView(_ row: MacViKeyQuickRow) -> some View {
        switch row.kind {
        case .toggle:
            toggleView(row)
        case .radio:
            radioView(row)
        case .fixedInfo:
            fixedInfoView(row)
        case .action:
            actionButton(row)
        case .separator:
            Divider()
        default:
            Text(row.title).font(.system(size: 12))
        }
    }

    private func groupView(_ row: MacViKeyQuickRow) -> some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: row.title)
            Card {
                ForEach(Array(row.children.enumerated()), id: \.offset) { _, child in
                    childView(child)
                }
            }
        }
    }

    /// Đã khoá cứng: chỉ là thông tin. Dùng dấu tích mờ thay vì checkbox tắt -
    /// checkbox tắt trông như một thứ đang lỗi.
    private func fixedInfoView(_ row: MacViKeyQuickRow) -> some View {
        HStack(spacing: 6) {
            Text("✓")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text(row.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
        }
        .mvkHelp(row.hint)
    }

    private func toggleView(_ row: MacViKeyQuickRow) -> some View {
        Toggle(isOn: Binding(
            get: { row.on },
            set: { _ in model.toggle(row) }
        )) {
            Text(row.title).font(.system(size: 12))
        }
        .mvkHelp(row.hint)
    }

    private func radioView(_ row: MacViKeyQuickRow) -> some View {
        Button {
            model.selectSwitchKey(row)
        } label: {
            HStack(spacing: 6) {
                Text(row.on ? "◉" : "○")
                    .font(.system(size: 12))
                    .foregroundColor(row.on ? Color.accentColor : Color.secondary)
                Text(row.title).font(.system(size: 12))
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .mvkHelp(row.hint)
    }

    // MARK: - Dòng trạng thái

    /// Thứ người dùng bấm nhiều nhất, nên là nút to nhất và nằm trên cùng.
    private var statusButton: some View {
        Button {
            model.tapStatusLine()
        } label: {
            Text(model.statusTitle)
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(StatusButtonStyle())
    }

    private func actionButton(_ row: MacViKeyQuickRow) -> some View {
        Button {
            model.tapAction(row)
        } label: {
            Text(row.title)
                .font(.system(size: 12))
                .foregroundColor(row.destructive
                                 ? Color(red: 0.78, green: 0.22, blue: 0.18)
                                 : Color.primary)
        }
        .mvkHelp(row.hint)
    }
}

/// Nút trạng thái: nền nhấn, bo góc, đổi độ sáng khi bấm.
private struct StatusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.28 : 0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.cornerRadius, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1)
            )
    }
}
