//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyControlPanelView.swift
//  MacViKey — bảng điều khiển: trạng thái bộ gõ và bảo trì
//
//  Bảng điều khiển cũ (ViewController + scene "MacViKeyPanel" trong
//  Main.storyboard) chỉ còn một tab thông tin, mấy popup đã khoá cứng và một
//  hàng phím chuyển bị ẩn đi bằng code - tức là phần lớn cửa sổ là tàn tích.
//
//  Bản này giữ đúng những việc mà chỉ nó làm được:
//    - Xem bộ gõ đang sống hay đã dừng, và khởi động lại.
//    - Khôi phục cấu hình mặc định. Đây là chỗ DUY NHẤT trong toàn ứng dụng có
//      chức năng này; bỏ bảng điều khiển mà không mang nó theo là mất tính năng.
//
//  Việc bật/tắt từng tuỳ chọn là của bảng nhanh, thông tin phiên bản và liên hệ
//  là của cửa sổ Giới thiệu - ở đây không nhân bản lại.
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

final class ControlPanelModel: ObservableObject {
    @Published var statusTitle: String = ""
    @Published var engineRunning: Bool = false

    private weak var actions: (any MacViKeyControlPanelActions)?

    init(actions: any MacViKeyControlPanelActions) {
        self.actions = actions
        refresh()
    }

    func refresh() {
        guard let actions else { return }
        statusTitle = actions.controlPanelStatusTitle()
        engineRunning = actions.controlPanelEngineIsRunning()
    }

    func restartEngine() {
        actions?.controlPanelRestartEngine()
        refresh()
    }

    func openQuickPanel() {
        actions?.controlPanelOpenQuickPanel()
    }

    func openAbout() {
        actions?.controlPanelOpenAbout()
    }

    func resetToDefaults() {
        actions?.controlPanelResetToDefaults()
        refresh()
    }
}

struct MacViKeyControlPanelView: View {
    @ObservedObject var model: ControlPanelModel
    /// Khôi phục mặc định ghi đè lựa chọn của người dùng, nên phải hỏi lại.
    @State private var confirmingReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            header
            engineSection
            shortcutsSection
            resetSection
        }
        .padding(Design.pagePadding)
        .frame(width: Design.windowWidth)
    }

    // MARK: - Đầu trang

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(MacViKeyInfo.appName)
                    .font(.system(size: 15, weight: .semibold))
                Text("Phiên bản \(MacViKeyInfo.versionString)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Bộ gõ

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: "Bộ gõ")
            Card {
                HStack(spacing: 8) {
                    // Đèn tròn: thấy ngay bộ gõ sống hay chết, không phải đọc chữ.
                    Circle()
                        .fill(model.engineRunning ? Color.green : Color.orange)
                        .frame(width: 9, height: 9)
                    Text(model.statusTitle)
                        .font(.system(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                Button {
                    model.restartEngine()
                } label: {
                    Text(model.engineRunning ? "Khởi động lại bộ gõ"
                                             : "Khởi động bộ gõ")
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Lối sang hai cửa sổ kia

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: "Mở")
            Card {
                HStack(spacing: 8) {
                    Button {
                        model.openQuickPanel()
                    } label: {
                        Text("Bảng nhanh")
                    }
                    .mvkHelp("Bật/tắt các tuỳ chọn, giống menu trên thanh trạng thái.")
                    Button {
                        model.openAbout()
                    } label: {
                        Text("Giới thiệu")
                    }
                    .mvkHelp("Phiên bản, liên kết, giấy phép và ủng hộ.")
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Khôi phục mặc định

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: "Khôi phục")
            Card {
                Text("Đặt lại toàn bộ tuỳ chọn về mặc định xuất xưởng. "
                     + "Kiểu gõ và bảng mã đã khoá cứng nên không đổi.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    confirmingReset = true
                } label: {
                    Text("Khôi phục cấu hình mặc định")
                        .foregroundColor(Color(red: 0.78, green: 0.22, blue: 0.18))
                }
                .padding(.top, 2)
            }
        }
        .alert(isPresented: $confirmingReset) {
            Alert(
                title: Text("Khôi phục cấu hình mặc định?"),
                message: Text("Mọi tuỳ chọn bạn đã đổi sẽ trở về mặc định."),
                primaryButton: .destructive(Text("Khôi phục")) {
                    model.resetToDefaults()
                },
                secondaryButton: .cancel(Text("Không"))
            )
        }
    }
}
