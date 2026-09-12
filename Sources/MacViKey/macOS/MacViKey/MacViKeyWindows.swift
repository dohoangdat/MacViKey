//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyWindows.swift
//  MacViKey — cửa ngõ cho Objective-C mở các cửa sổ SwiftUI
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

/// Dựng cửa sổ cho một view SwiftUI.
///
/// Vì sao tự dựng NSWindow chứ không dùng `Window`/`Settings` của SwiftUI App:
/// MacViKey là ứng dụng LSUIElement với NSApplicationMain sẵn có, vòng đời do
/// AppDelegate giữ. Đổi sang SwiftUI App life-cycle là viết lại chỗ đó, mà chỗ
/// đó đang gánh event tap - không đáng đổi lấy hai cửa sổ phụ.
private func makeHostedWindow<Content: View>(title: String,
                                            content: Content) -> NSWindow {
    let hosting = NSHostingController(rootView: content)
    let window = NSWindow(contentViewController: hosting)
    window.title = title
    window.styleMask = [.titled, .closable]
    window.isReleasedWhenClosed = false
    // Kích thước do SwiftUI tự quyết (view đã cố định bề rộng); gọi
    // setContentSize theo fittingSize để cửa sổ không cắt mất nội dung.
    window.setContentSize(hosting.view.fittingSize)
    window.center()
    return window
}

/// Đưa một cửa sổ lên trước. Với ứng dụng LSUIElement thì phải activate app
/// trước, nếu không cửa sổ hiện ra mà không nhận được bàn phím.
private func present(_ window: NSWindow) {
    if window.isVisible { return }
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.level = .floating
}

// MARK: - Cửa sổ Giới thiệu

@objc(MacViKeyAboutWindow)
final class MacViKeyAboutWindow: NSObject {
    private var window: NSWindow?

    @objc func show() {
        if window == nil {
            window = makeHostedWindow(title: "Giới thiệu \(MacViKeyInfo.appName)",
                                      content: MacViKeyAboutView())
        }
        guard let window else { return }
        present(window)
    }
}

// MARK: - Bảng nhanh

@objc(MacViKeyQuickPanelWindow)
final class MacViKeyQuickPanelWindow: NSObject {
    private var window: NSWindow?
    private let model: QuickPanelModel

    @objc init(actions: any MacViKeyQuickPanelActions) {
        self.model = QuickPanelModel(actions: actions)
        super.init()
    }

    @objc func show() {
        model.refresh()
        if window == nil {
            let title = MacViKeyMenuLayout.string("quickPanel.title", fallback: "MacViKey")
            window = makeHostedWindow(title: title,
                                      content: MacViKeyQuickPanelView(model: model))
        }
        guard let window else { return }
        present(window)
    }

    /// Gọi từ fillData: bảng nhanh, menu và prefs không bao giờ lệch nhau.
    @objc func refresh() {
        guard window != nil else { return }
        model.refresh()
    }
}

// MARK: - Bang dieu khien

@objc(MacViKeyControlPanelWindow)
final class MacViKeyControlPanelWindow: NSObject {
    private var window: NSWindow?
    private let model: ControlPanelModel

    @objc init(actions: any MacViKeyControlPanelActions) {
        self.model = ControlPanelModel(actions: actions)
        super.init()
    }

    @objc func show() {
        model.refresh()
        if window == nil {
            window = makeHostedWindow(title: "Bảng điều khiển",
                                      content: MacViKeyControlPanelView(model: model))
        }
        guard let window else { return }
        present(window)
    }

    /// Gọi từ fillData, cùng nhịp với bảng nhanh.
    @objc func refresh() {
        guard window != nil else { return }
        model.refresh()
    }
}
