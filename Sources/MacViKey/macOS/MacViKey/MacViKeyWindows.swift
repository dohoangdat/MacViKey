//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyWindows.swift
//  MacViKey — cửa ngõ cho Objective-C mở cửa sổ Cài đặt
//
//  AppDelegate vẫn là Objective-C, nên mọi thứ Swift mà nó cần đều phải đi qua
//  @objc. Gom vào một file để chỗ giao nhau giữa hai ngôn ngữ chỉ có một nơi.
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

/// Cửa sổ Cài đặt - cửa sổ duy nhất của ứng dụng.
///
/// Vì sao tự dựng NSWindow chứ không dùng `Settings`/`Window` của SwiftUI App:
/// MacViKey là ứng dụng LSUIElement với NSApplicationMain sẵn có, vòng đời do
/// AppDelegate giữ. Đổi sang SwiftUI App life-cycle là viết lại chỗ đó, mà chỗ
/// đó đang gánh event tap - không đáng đổi lấy một cửa sổ.
@objc(MacViKeySettingsWindow)
final class MacViKeySettingsWindow: NSObject {
    private var window: NSWindow?
    private let model: SettingsModel

    @objc init(actions: any MacViKeySettingsActions) {
        self.model = SettingsModel(actions: actions)
        super.init()
    }

    @objc func show() {
        model.refresh()
        if window == nil {
            let hosting = NSHostingController(
                rootView: MacViKeySettingsView(model: model))
            let w = NSWindow(contentViewController: hosting)
            w.title = MacViKeyMenuLayout.string("settings.title",
                                                fallback: "Cài đặt MacViKey")
            w.styleMask = [.titled, .closable, .fullSizeContentView]
            // Thanh bên của NavigationView chạy lên sát thanh tiêu đề, nên để
            // thanh tiêu đề trong suốt cho hai vùng liền một khối.
            w.titlebarAppearsTransparent = true
            w.isReleasedWhenClosed = false
            w.setContentSize(hosting.view.fittingSize)
            w.center()
            window = w
        }
        guard let window = window else { return }
        if window.isVisible { return }
        // Ứng dụng LSUIElement phải activate trước, nếu không cửa sổ hiện ra mà
        // không nhận được bàn phím.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// Gọi từ fillData: cửa sổ, menu và prefs không bao giờ lệch nhau.
    @objc func refresh() {
        guard window != nil else { return }
        model.refresh()
    }
}
