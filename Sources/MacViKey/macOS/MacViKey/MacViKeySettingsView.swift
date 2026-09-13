//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeySettingsView.swift
//  MacViKey — cửa sổ Cài đặt: thanh bên trái + vùng nội dung
//
//  Đây là cửa sổ DUY NHẤT của ứng dụng. Menu trên thanh trạng thái chỉ còn
//  trạng thái, thông tin phím chuyển và nút mở cửa sổ này.
//
//  Dữ liệu do phía Objective-C dựng (xem MacViKeyQuickRow.h): nó đi cây
//  "settings" trong MenuLayout.json với đúng bộ lọc mà menu dùng, rồi trả ra
//  danh sách trang + dòng. Ở đây chỉ vẽ và gọi ngược lại - không có luật nghiệp
//  vụ nào.
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

/// Cầu nối trạng thái. Cửa sổ phải khớp với prefs mọi lúc, mà prefs bị đổi từ
/// nhiều nơi (menu, phím tắt, engine). Nên không giữ bản sao trạng thái nào:
/// mỗi lần `refresh()` là hỏi lại Objective-C toàn bộ danh sách.
final class SettingsModel: ObservableObject {
    @Published var pages: [MacViKeyQuickRow] = []
    @Published var statusTitle: String = ""
    @Published var vietnamese: Bool = false
    @Published var engineRunning: Bool = false
    @Published var accessibilityGranted: Bool = false

    private weak var actions: (any MacViKeySettingsActions)?

    init(actions: any MacViKeySettingsActions) {
        self.actions = actions
        refresh()
    }

    func refresh() {
        guard let actions = actions else { return }
        pages = actions.settingsPages()
        statusTitle = actions.settingsStatusTitle()
        vietnamese = actions.settingsVietnameseIsOn()
        engineRunning = actions.settingsEngineIsRunning()
        accessibilityGranted = actions.settingsAccessibilityIsGranted()
    }

    func setVietnamese(_ on: Bool) {
        actions?.settingsSetVietnamese(on)
        refresh()
    }

    func restartEngine() {
        actions?.settingsRestartEngine()
        refresh()
    }

    func grantAccessibility() {
        actions?.settingsGrantAccessibility()
        refresh()
    }

    func toggle(_ row: MacViKeyQuickRow) {
        actions?.settingsToggleOption(withTag: row.tag)
        refresh()
    }

    func selectSwitchKey(_ row: MacViKeyQuickRow) {
        actions?.settingsSelectSwitchKey(at: row.tag)
        refresh()
    }

    func runAction(_ row: MacViKeyQuickRow) {
        actions?.settingsRunAction(withId: row.rowId)
        refresh()
    }
}

struct MacViKeySettingsView: View {
    @ObservedObject var model: SettingsModel
    @State private var selection: String?

    var body: some View {
        NavigationView {
            sidebar
            detail
        }
        .frame(width: Design.sidebarWidth + Design.detailWidth,
               height: Design.windowHeight)
        .onAppear {
            if selection == nil {
                selection = model.pages.first?.rowId
            }
        }
    }

    // MARK: - Thanh bên

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader
            sidebarList
        }
        .frame(width: Design.sidebarWidth)
    }

    /// Logo + tên ở góc trên trái thanh bên: cửa sổ không có thanh tiêu đề đặc
    /// nên nếu không có gì ở đây thì góc đó trống trơn.
    private var brandHeader: some View {
        HStack(spacing: 9) {
            Image(nsImage: NSImage(named: "logo_macvikey")
                  ?? NSApp.applicationIconImage)
                .resizable()
                .frame(width: 26, height: 26)
            Text(MacViKeyInfo.appName)
                .font(.system(size: 14, weight: .semibold))
            Spacer(minLength: 0)
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private var sidebarList: some View {
        List(selection: $selection) {
            ForEach(model.pages, id: \.rowId) { page in
                NavigationLink(
                    destination: detailFor(page),
                    tag: page.rowId,
                    selection: $selection
                ) {
                    Label {
                        Text(page.title)
                    } icon: {
                        Image(systemName: page.symbol ?? "circle")
                    }
                }
                .mvkHelp(page.hint)
            }
        }
        .listStyle(SidebarListStyle())
    }

    // MARK: - Vùng nội dung

    /// Trang hiện tại. Khi chưa chọn gì thì lấy trang đầu, để cửa sổ không mở ra
    /// trống trơn.
    @ViewBuilder
    private var detail: some View {
        if let page = model.pages.first(where: { $0.rowId == selection })
            ?? model.pages.first {
            detailFor(page)
        } else {
            Text("Không đọc được MenuLayout.json")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func detailFor(_ page: MacViKeyQuickRow) -> some View {
        if page.kind == .infoPage {
            // Hai trang thông tin tự vẽ, nhận ra nhau bằng id trong JSON.
            if page.rowId == "page.donate" {
                MacViKeyDonatePage()
            } else {
                MacViKeyAboutPage()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.sectionSpacing) {
                    PageTitle(title: page.title, subtitle: page.hint)
                    pageBody(page)
                    Spacer(minLength: 0)
                }
                .padding(Design.pagePadding)
                .frame(width: Design.detailWidth, alignment: .leading)
            }
        }
    }

    /// Nội dung một trang. Các dòng cùng loại được gom vào một khung: bốn dòng
    /// bật/tắt rời rạc trông như bốn thứ không liên quan, gom lại thành một bảng
    /// thì đọc được thành "các tuỳ chọn".
    @ViewBuilder
    private func pageBody(_ page: MacViKeyQuickRow) -> some View {
        let rows = page.children
        let status = rows.filter { $0.kind == .status }
        let fixed = rows.filter { $0.kind == .fixedInfo }
        let radios = rows.filter { $0.kind == .radio }
        let toggles = rows.filter { $0.kind == .toggle }
        // Nhom Bao tri gom ca dong chi doc lan dong hanh dong, giu nguyen thu
        // tu trong JSON - phien ban dung truoc lich su cap nhat la co chu y.
        let maintenance = rows.filter { $0.kind == .action || $0.kind == .infoValue }

        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            if !status.isEmpty {
                engineGroup(status)
            }
            if !radios.isEmpty {
                Card(spacing: 0) {
                    ForEach(Array(radios.enumerated()), id: \.offset) { index, row in
                        if index > 0 { Divider() }
                        radioRow(row)
                    }
                }
            }
            if !toggles.isEmpty {
                labelledCard(MacViKeyMenuLayout.string("settings.section.startup",
                                                       fallback: "Tuỳ chọn")) {
                    ForEach(Array(toggles.enumerated()), id: \.offset) { _, row in
                        toggleRow(row)
                    }
                }
            }
            if !fixed.isEmpty {
                labelledCard(MacViKeyMenuLayout.string("settings.section.fixed",
                                                       fallback: "Đã khoá cố định")) {
                    ForEach(Array(fixed.enumerated()), id: \.offset) { _, row in
                        fixedRow(row)
                    }
                }
            }
            if !maintenance.isEmpty {
                labelledCard(MacViKeyMenuLayout.string("settings.section.maintenance",
                                                       fallback: "Bảo trì")) {
                    ForEach(Array(maintenance.enumerated()), id: \.offset) { _, row in
                        if row.kind == .infoValue {
                            infoValueRow(row)
                        } else {
                            ActionRow(row: row, model: model)
                        }
                    }
                }
            }
        }
    }

    private func labelledCard<C: View>(_ title: String,
                                       @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Design.tightSpacing) {
            SectionHeader(title: title)
            Card { content() }
        }
    }

    // MARK: - Nhóm chế độ gõ + bộ gõ

    private func engineGroup(_ status: [MacViKeyQuickRow]) -> some View {
        VStack(alignment: .leading, spacing: Design.sectionSpacing) {
            VStack(alignment: .leading, spacing: Design.tightSpacing) {
                SectionHeader(title: MacViKeyMenuLayout.string(
                    "settings.section.mode", fallback: "Chế độ gõ"))
                Card {
                    // Chọn chế độ bằng segmented: hai lựa chọn loại trừ nhau,
                    // thấy ngay đang ở đâu - hơn một nút "đổi" mà phải đọc chữ
                    // mới biết.
                    Picker(selection: Binding(
                        get: { model.vietnamese },
                        set: { model.setVietnamese($0) }
                    ), label: EmptyView()) {
                        Text(MacViKeyMenuLayout.string("settings.mode.vi",
                                                       fallback: "Tiếng Việt")).tag(true)
                        Text(MacViKeyMenuLayout.string("settings.mode.en",
                                                       fallback: "English")).tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .mvkHelp(status.first?.hint)
                }
            }

            // Hai điều kiện để bộ gõ chạy được, tách thành hai dòng riêng: mỗi
            // cái hỏng một kiểu và sửa một kiểu, gộp lại thì người dùng không
            // biết phải làm gì.
            VStack(alignment: .leading, spacing: Design.tightSpacing) {
                SectionHeader(title: MacViKeyMenuLayout.string(
                    "settings.section.status", fallback: "Trạng thái"))
                Card {
                    StateRow(
                        label: MacViKeyMenuLayout.string(
                            "settings.accessibility.label", fallback: "Quyền Trợ năng"),
                        ok: model.accessibilityGranted,
                        okText: MacViKeyMenuLayout.string(
                            "settings.accessibility.granted", fallback: "Đã cấp"),
                        badText: MacViKeyMenuLayout.string(
                            "settings.accessibility.missing", fallback: "Chưa cấp"),
                        buttonTitle: MacViKeyMenuLayout.string(
                            "settings.accessibility.button", fallback: "Cấp quyền"),
                        action: { model.grantAccessibility() })

                    Divider()

                    StateRow(
                        label: MacViKeyMenuLayout.string(
                            "settings.engine.label", fallback: "Bộ gõ"),
                        ok: model.engineRunning,
                        okText: MacViKeyMenuLayout.string(
                            "settings.engine.running", fallback: "Đang hoạt động"),
                        badText: MacViKeyMenuLayout.string(
                            "settings.engine.stopped", fallback: "Đã dừng"),
                        buttonTitle: MacViKeyMenuLayout.string(
                            "settings.engine.button", fallback: "Khởi động lại"),
                        // Bộ gõ khởi động lại được kể cả khi đang chạy: đó là
                        // đường thoát khi nó chạy mà gõ vẫn sai.
                        alwaysShowButton: true,
                        action: { model.restartEngine() })
                }
            }
        }
    }

    // MARK: - Các dạng dòng

    private func toggleRow(_ row: MacViKeyQuickRow) -> some View {
        Toggle(isOn: Binding(
            get: { row.on },
            set: { _ in model.toggle(row) }
        )) {
            Text(row.title).font(.system(size: 12))
        }
        .toggleStyle(BrandSwitchToggleStyle())
        .mvkHelp(row.hint)
    }

    /// Chọn phím chuyển. Cả dòng bấm được, không bắt người dùng nhắm vào cái
    /// vòng tròn bé xíu.
    private func radioRow(_ row: MacViKeyQuickRow) -> some View {
        Button {
            model.selectSwitchKey(row)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: row.on ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(row.on ? Color.accentColor : Color.secondary)
                Text(row.title).font(.system(size: 12))
                Spacer(minLength: 8)
                // Ky hieu phim canh phai, thang hang voi nut va phim gat o cac
                // trang khac. Chu de doc, ky hieu de doi chieu voi ban phim.
                if let symbols = row.value, !symbols.isEmpty {
                    Text(symbols)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .mvkHelp(row.hint)
    }

    /// Dòng chỉ đọc "nhãn — giá trị", canh phải cho thẳng hàng với nút và phím gạt.
    private func infoValueRow(_ row: MacViKeyQuickRow) -> some View {
        HStack(spacing: 12) {
            Text(row.title).font(.system(size: 12))
            Spacer(minLength: 8)
            Text(row.value ?? "")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .mvkHelp(row.hint)
    }

    private func fixedRow(_ row: MacViKeyQuickRow) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(row.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
        }
        .mvkHelp(row.hint)
    }
}

/// Nút hành động. Tách thành view riêng vì hành động phá huỷ cần `@State` cho
/// hộp xác nhận, mà `@State` không dùng được trong một hàm trả về view.
private struct ActionRow: View {
    let row: MacViKeyQuickRow
    let model: SettingsModel
    @State private var confirming = false

    var body: some View {
        // Nhan trai, nut phai - thang hang voi cac phim gat o nhom ben tren.
        HStack(spacing: 12) {
            Text(row.title)
                .font(.system(size: 12))
            Spacer(minLength: 8)
            Button {
                if row.destructive {
                    confirming = true
                } else {
                    model.runAction(row)
                }
            } label: {
                Text(row.buttonTitle ?? row.title)
                    .font(.system(size: 12))
                    .foregroundColor(row.destructive ? Design.danger : Color.primary)
            }
            .mvkHelp(row.hint)
        }
        .alert(isPresented: $confirming) {
            Alert(
                title: Text(row.title + "?"),
                message: Text("Mọi tuỳ chọn bạn đã đổi sẽ trở về mặc định."),
                primaryButton: .destructive(Text("Khôi phục")) {
                    model.runAction(row)
                },
                secondaryButton: .cancel(Text("Không"))
            )
        }
    }
}

/// Một dòng trạng thái: đèn, nhãn, tình trạng bằng chữ, và nút sửa khi hỏng.
///
/// Hiện tình trạng bằng CHỮ chứ không chỉ bằng màu đèn - "Đã cấp" / "Chưa cấp"
/// đọc là hiểu, còn một chấm xanh thì phải đoán.
private struct StateRow: View {
    let label: String
    let ok: Bool
    let okText: String
    let badText: String
    let buttonTitle: String
    var alwaysShowButton: Bool = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            StatusDot(on: ok)
            Text(label).font(.system(size: 12))
            Spacer(minLength: 8)
            Text(ok ? okText : badText)
                .font(.system(size: 12))
                .foregroundColor(ok ? .secondary : Design.danger)
            if !ok || alwaysShowButton {
                Button(action: action) {
                    Text(buttonTitle).font(.system(size: 12))
                }
            }
        }
    }
}
