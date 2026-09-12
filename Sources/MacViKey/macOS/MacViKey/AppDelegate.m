//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  AppDelegate.m
//  MacViKey
//
//

#import "AppDelegate.h"
#import "MJAccessibilityUtils.h"
#import "MacViKeyAX.h"
#import "MacViKeyConfig.h"
#import "MacViKeyInfo.h"
#import "MacViKeyManager.h"
#import "MacViKeyMenuLayout.h"
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#import "MacViKeyQuickRow.h"
// Header do Xcode sinh ra tu lop @objc ben Swift (MacViKeySettingsWindow).
// Ten file theo PRODUCT_MODULE_NAME.
#import "MacViKey-Swift.h"
#include <libproc.h>
#include <sys/proc_info.h>

AppDelegate *appDelegate;

// MacViKey: giam sat suc khoe event tap
extern BOOL MacViKeyIsEventTapAlive(void);
extern BOOL MacViKeyReenableEventTap(void);
extern int _macViKeyTapDisabledCount;

// MacViKey: loai tru ung dung + duong Accessibility
extern NSString *MacViKeyCurrentAppName(void);
extern void OnTableCodeChange(void);
extern void OnInputMethodChanged(void);
extern void RequestNewSession(void);
extern void OnActiveAppChanged(void);

// see document in Engine.h
int vLanguage = 1;
int vInputType = 0;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
// MacViKey: chi con 4 to hop phim chuyen co dinh, luon keu beep (xem
// MacViKeyConfig.h).
#define DEFAULT_SWITCH_STATUS MACVIKEY_SWITCH_DEFAULT
int vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
int vRestoreIfWrongSpelling = 0;
int vFixRecommendBrowser = 1;
int vSendKeyStepByStep = 0;
int vUseSmartSwitchKey = 1;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 1;          // new on version 2.0
int vOtherLanguage = 1;         // new on version 2.0
int vTempOffEngineByHotKey = 0; // new on version 2.0

int vShowIconOnDock = 1; // MacViKey: mac dinh hien icon tren Dock

int vPerformLayoutCompat = 0;

// beta feature
int vFixChromiumBrowser = 0; // new on version 2.0


// Khoa tuy chon <-> (ten trong prefs, bien engine). Bien NULL = chi luu prefs.
typedef NS_ENUM(NSInteger, MacViKeyOptionTag) {
  MacViKeyOptionFreeMark = 110,
  MacViKeyOptionFixRecommendBrowser,
  MacViKeyOptionUpperCaseFirstChar,
  MacViKeyOptionSmartSwitchKey,
  MacViKeyOptionAllowZFWJ,
  MacViKeyOptionTempOffEngine,
  MacViKeyOptionOtherLanguage,

  MacViKeyOptionRunOnStartup = 130,
  MacViKeyOptionShowIconOnDock,
  MacViKeyOptionGrayIcon,
  MacViKeyOptionSendKeyStepByStep,
  MacViKeyOptionFixChromium,
  MacViKeyOptionLayoutCompat,
  MacViKeyOptionShowUIOnStartup,
  MacViKeyOptionShowIconOnMenuBar,
};

@interface AppDelegate () <MacViKeySettingsActions>

@end

@implementation AppDelegate {
  // Cua so DUY NHAT cua ung dung: Cai dat (SwiftUI). Menu tha xuong chi con
  // trang thai, thong tin phim chuyen va nut mo cua so nay.
  MacViKeySettingsWindow *_settingsWindow;

  NSStatusItem *statusItem;
  NSMenu *theMenu;

  // Dong dau menu: gop trang thai bo go + bat/tat tieng Viet.
  NSMenuItem *mnuStatusLine;
  // Dong thong tin chi ro dang dung to hop phim nao (khong bam duoc).
  NSMenuItem *mnuSwitchKeyInfo;

  // MacViKey
  NSTimer *_permissionPoll;
  NSTimer *_tapWatchdog;

  // Phim chuyen gio nam trong cua so Cai dat, nhung thu tu van do
  // MenuLayout.json quyet dinh: onSwitchKeySelected: tra cuu theo chi so trong
  // mnuSwitchKeyValues, nen hai mang nay phai duoc dung truoc khi ve cua so.
  NSMutableArray<NSNumber *> *mnuSwitchKeyValues;
  NSMutableArray<NSString *> *mnuSwitchKeyNames;
}

// MacViKey: KHONG thoat app khi chua co quyen.
// Ban goc hien NSAlert roi terminate ngay - nhung voi app LSUIElement chua duoc
// activate, alert khong render duoc, nen app "chet im lang" va nguoi dung khong
// hieu chuyen gi. Thay bang: bat dialog he thong, hien icon canh bao tren menu
// bar, va cho den khi duoc cap quyen thi tu dong khoi dong bo go.
- (void)askPermission {
  NSLog(@"[MacViKey] Chua co quyen Tro nang - dang mo dialog he thong.");

  // Dua app vao danh sach Tro nang va hien dialog "Open System Settings".
  MJAccessibilityOpenPanel();

  // Van dung menu bar de nguoi dung thay app dang song va biet phai lam gi.
  [self createStatusBarMenu];
  [self macViKeyUpdateStatusLine];

  // Cho quyen duoc cap, khong bat nguoi dung mo lai app.
  _permissionPoll =
      [NSTimer scheduledTimerWithTimeInterval:2.0
                                       target:self
                                     selector:@selector(checkPermissionGranted)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)checkPermissionGranted {
  if (!MJAccessibilityIsEnabled())
    return;

  NSLog(@"[MacViKey] Da duoc cap quyen - khoi dong bo go.");
  [_permissionPoll invalidate];
  _permissionPoll = nil;

  [MacViKeyManager initEventTap];
  [self startTapWatchdog];
  [self macViKeyUpdateStatusLine];

  [MacViKeyManager
      showMessage:nil
          message:@"MacViKey đã sẵn sàng!"
           subMsg:@"Bộ gõ đã được kích hoạt, bạn có thể gõ tiếng Việt ngay."];
}

// MacViKey: ghi đè config bị khoá, chạy trước mọi thứ khác để prefs cũ không
// lọt vào.
- (void)applyMacViKeyFixedConfig {
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  // Khoi dong cung may la mac dinh BAT: bo go khong tu chay thi nguoi dung go
  // ra tieng Anh ma khong hieu tai sao. Dung registerDefaults nen lua chon tat
  // cua nguoi dung (da ghi vao prefs) van duoc ton trong.
  // Hien bieu tuong tren thanh menu la mac dinh BAT - do la cho duy nhat nguoi
  // dung thay bo go dang o che do nao.
  // Hien bieu tuong tren thanh Dock cung mac dinh BAT.
  [prefs registerDefaults:@{
    @"RunOnStartup" : @1,
    @"vShowIconOnMenuBar" : @1,
    @"vShowIconOnDock" : @1
  }];
  vInputType = MACVIKEY_FIXED_INPUT_TYPE;
  [prefs setInteger:vInputType forKey:@"InputType"];
  vCodeTable = MACVIKEY_FIXED_CODE_TABLE;
  [prefs setInteger:vCodeTable forKey:@"CodeTable"];
  // Nhớ bảng mã theo ứng dụng chỉ có nghĩa khi có nhiều bảng mã.
  vRememberCode = 0;
  [prefs setInteger:vRememberCode forKey:@"vRememberCode"];
  // Các tuỳ chọn bị ẩn khỏi GUI đều khoá về TẮT.
  vCheckSpelling = 0;
  [prefs setInteger:vCheckSpelling forKey:@"Spelling"];
  // A8 chỉ hoạt động cùng A5, A5 đã tắt vĩnh viễn nên A8 là tuỳ chọn chết.
  vRestoreIfWrongSpelling = 0;
  [prefs setInteger:vRestoreIfWrongSpelling forKey:@"RestoreIfInvalidWord"];
  vUseModernOrthography = 0;
  [prefs setInteger:vUseModernOrthography forKey:@"ModernOrthography"];
  vQuickTelex = 0;
  [prefs setInteger:vQuickTelex forKey:@"QuickTelex"];
  vQuickEndConsonant = 0;
  [prefs setInteger:vQuickEndConsonant forKey:@"vQuickEndConsonant"];
  vTempOffSpelling = 0;
  [prefs setInteger:vTempOffSpelling forKey:@"vTempOffSpelling"];
  // Phim chuyen chi duoc phep la 1 trong 4 to hop, va luon keu beep.
  vSwitchKeyStatus = (int)[prefs integerForKey:@"SwitchKeyStatus"];
  if (![self macViKeyIsSupportedSwitchKey:vSwitchKeyStatus])
    vSwitchKeyStatus = MACVIKEY_SWITCH_DEFAULT;
  vSwitchKeyStatus |= MACVIKEY_SWITCH_BEEP;
  [prefs setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

- (BOOL)macViKeyIsSupportedSwitchKey:(int)value {
  int v = value | MACVIKEY_SWITCH_BEEP;
  return v == MACVIKEY_SWITCH_CMD_SHIFT || v == MACVIKEY_SWITCH_OPT_SHIFT ||
         v == MACVIKEY_SWITCH_CTRL_SHIFT || v == MACVIKEY_SWITCH_FN_SHIFT;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  appDelegate = self;

  [self applyMacViKeyFixedConfig];

  [self registerSupportedNotification];

  // set quick tooltip
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:50]
                                            forKey:@"NSInitialToolTipDelay"];

  // check whether this app has been launched before that or not
  // Only check instances owned by current user (for multi-user/Fast User
  // Switching support)
  uid_t currentUID = getuid();
  NSArray<NSRunningApplication *> *runningApps =
      [[NSWorkspace sharedWorkspace] runningApplications];
  pid_t myPID = [[NSProcessInfo processInfo] processIdentifier];
  BOOL alreadyRunning = NO;

  for (NSRunningApplication *app in runningApps) {
    if ([app.bundleIdentifier isEqualToString:MACVIKEY_BUNDLE] &&
        app.processIdentifier != myPID) {
      pid_t pid = app.processIdentifier;
      struct proc_bsdinfo proc;
      int size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &proc, sizeof(proc));
      if (size == sizeof(proc) && proc.pbi_uid == currentUID) {
        alreadyRunning = YES;
        break;
      }
    }
  }

  if (alreadyRunning) {
    [NSApp terminate:nil];
    return;
  }

  // Dong bo login item TRUOC nhanh xin quyen: askPermission return som, neu de
  // o cuoi ham thi may chua cap quyen Tro nang se khong bao gio dang ky khoi
  // dong cung may.
  [self setRunOnStartup:[[NSUserDefaults standardUserDefaults]
                            integerForKey:@"RunOnStartup"] != 0];

  // Icon tren Dock: ap dung TRUOC nhanh xin quyen. Ban cu doc pref trong ca hai
  // nhanh nhung chi nhanh da co quyen moi goi setActivationPolicy - may chua cap
  // quyen thi khong co icon, dung luc nguoi dung can tim app nhat.
  vShowIconOnDock = (int)[[NSUserDefaults standardUserDefaults]
      integerForKey:@"vShowIconOnDock"];
  [self showIconOnDock:vShowIconOnDock != 0];

  // check if user granted Accessabilty permission
  if (!MJAccessibilityIsEnabled()) {
    [self askPermission];
    return; // askPermission se tu khoi dong bo go khi quyen duoc cap
  }

  if (vSwitchKeyStatus & 0x8000)
    NSBeep();

  [self createStatusBarMenu];

  // init
  dispatch_async(dispatch_get_main_queue(), ^{
    if (![MacViKeyManager initEventTap]) {
      [self onSettingsSelected];
    } else {
      NSInteger showui = [[NSUserDefaults standardUserDefaults]
          integerForKey:@"ShowUIOnStartup"];
      if (showui == 1) {
        [self onSettingsSelected];
      }
    }
    [self startTapWatchdog];
  });

  // load default config if is first launch
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NonFirstTime"] == 0) {
    [self loadDefaultConfig];
  }
  [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"NonFirstTime"];

}

// Click vao .app khi app da chay: mo cua so Cai dat. Day cung la duong quay lai
// duy nhat khi nguoi dung da an bieu tuong khoi thanh menu.
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                    hasVisibleWindows:(BOOL)flag {
  [self onSettingsSelected];
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

/// Doi chu cua mot muc menu. Huong dan (neu co) di theo toolTip - macOS tu
/// hien ra sau khoang mot giay khi re chuot, khong danh dau gi tren chu.
- (void)macViKeySetTitle:(NSString *)title forItem:(NSMenuItem *)item {
  item.title = title;
}

#pragma mark -MacViKey: dung menu tu MenuLayout.json

// Thu tu va chu cua menu nam trong Resources/MenuLayout.json. O day chi con
// phan "id nao gan hanh dong gi" - sua menu thi sua file JSON, khong sua day.

// id trong JSON -> tag cua tuy chon bat/tat.
- (NSDictionary<NSString *, NSNumber *> *)macViKeyOptionTagsById {
  static NSDictionary *map = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    map = @{
      @"option.freeMark" : @(MacViKeyOptionFreeMark),
      @"option.fixRecommendBrowser" : @(MacViKeyOptionFixRecommendBrowser),
      @"option.upperCaseFirstChar" : @(MacViKeyOptionUpperCaseFirstChar),
      @"option.smartSwitchKey" : @(MacViKeyOptionSmartSwitchKey),
      @"option.allowZFWJ" : @(MacViKeyOptionAllowZFWJ),
      @"option.tempOffEngine" : @(MacViKeyOptionTempOffEngine),
      @"option.otherLanguage" : @(MacViKeyOptionOtherLanguage),
      @"option.runOnStartup" : @(MacViKeyOptionRunOnStartup),
      @"option.showIconOnDock" : @(MacViKeyOptionShowIconOnDock),
      @"option.grayIcon" : @(MacViKeyOptionGrayIcon),
      @"option.sendKeyStepByStep" : @(MacViKeyOptionSendKeyStepByStep),
      @"option.fixChromium" : @(MacViKeyOptionFixChromium),
      @"option.layoutCompat" : @(MacViKeyOptionLayoutCompat),
      @"option.showUIOnStartup" : @(MacViKeyOptionShowUIOnStartup),
      @"option.showIconOnMenuBar" : @(MacViKeyOptionShowIconOnMenuBar),
    };
  });
  return map;
}

// id trong JSON -> to hop phim chuyen Viet/Anh.
- (NSDictionary<NSString *, NSNumber *> *)macViKeySwitchKeyValuesById {
  static NSDictionary *map = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    map = @{
      @"switchKey.cmdShift" : @(MACVIKEY_SWITCH_CMD_SHIFT),
      @"switchKey.optShift" : @(MACVIKEY_SWITCH_OPT_SHIFT),
      @"switchKey.ctrlShift" : @(MACVIKEY_SWITCH_CTRL_SHIFT),
      @"switchKey.fnShift" : @(MACVIKEY_SWITCH_FN_SHIFT),
    };
  });
  return map;
}

// Muc bi tat boi co bien dich trong MacViKeyConfig.h: cu de trong JSON, o day
// bo qua.
- (BOOL)macViKeyNodeEnabled:(NSString *)nodeId {
  static NSSet<NSString *> *disabled = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSMutableSet *set = [NSMutableSet set];
    // Chon kieu go / bang ma: da khoa cung trong MacViKeyConfig.h.
    [set addObjectsFromArray:@[
      @"inputTypeMenu", @"codeMenu", @"code.unicode", @"code.tcvn3",
      @"code.vniWindows"
    ]];
    // Toan bo tuy chon go da bi khoa cung trong MacViKeyInit() (ep ve 0 va ghi
    // lai prefs) -> an ca menu cha lan cac muc con. Ba muc sua loi ben "He
    // thong" cung vay. Them lai vao MenuLayout.json cung khong bat lai duoc:
    // phai mo khoa trong MacViKeyHook.mm truoc.
    [set addObjectsFromArray:@[
      @"typingOptionsMenu", @"option.freeMark", @"option.upperCaseFirstChar",
      @"option.allowZFWJ", @"option.smartSwitchKey", @"option.tempOffEngine",
      @"option.otherLanguage", @"option.fixRecommendBrowser",
      @"option.sendKeyStepByStep", @"option.fixChromium", @"option.layoutCompat"
    ]];
    disabled = set;
  });
  return ![disabled containsObject:nodeId];
}

/// Tao mot muc menu tu id trong JSON. Tra ve nil neu id khong duoc biet.
///
/// Menu tha xuong duoc giu that gon - moi cau hinh da chuyen sang cua so Cai
/// dat. Nen o day chi con bon id; them mot muc cau hinh vao "menu" trong JSON
/// se bi bo qua kem canh bao, dung cho.
- (NSMenuItem *)macViKeyAddNode:(NSString *)nodeId
                          title:(NSString *)title
                         toMenu:(NSMenu *)menu {
  // Mot dong duy nhat cho ca trang thai bo go lan bat/tat tieng Viet.
  // "inputMethod"/"engineStatus" la ten cu, van chap nhan de JSON cu chay duoc.
  if ([nodeId isEqualToString:@"statusLine"] ||
      [nodeId isEqualToString:@"inputMethod"] ||
      [nodeId isEqualToString:@"engineStatus"]) {
    if (mnuStatusLine != nil)
      return nil; // da co roi - khong tao dong thu hai
    mnuStatusLine = [menu addItemWithTitle:title
                                    action:@selector(onStatusLineClicked)
                             keyEquivalent:@""];
    return mnuStatusLine;
  }

  if ([nodeId isEqualToString:@"switchKeyInfo"]) {
    if (mnuSwitchKeyInfo != nil)
      return nil;
    mnuSwitchKeyInfo = [menu addItemWithTitle:title action:nil keyEquivalent:@""];
    [mnuSwitchKeyInfo setEnabled:NO];
    return mnuSwitchKeyInfo;
  }

  // "controlPanel"/"about" la ten cu: deu mo cung mot cua so Cai dat.
  if ([nodeId isEqualToString:@"openSettings"] ||
      [nodeId isEqualToString:@"controlPanel"] ||
      [nodeId isEqualToString:@"about"]) {
    return [menu addItemWithTitle:title
                          action:@selector(onSettingsSelected)
                   keyEquivalent:@","];
  }

  if ([nodeId isEqualToString:@"quit"]) {
    return [menu addItemWithTitle:title
                           action:@selector(terminate:)
                    keyEquivalent:@"q"];
  }

  NSLog(@"[MacViKey] MenuLayout.json: muc \"%@\" khong thuoc menu tha xuong "
        @"(moi cau hinh nam trong \"settings\"), bo qua.", nodeId);
  return nil;
}

- (void)macViKeyBuildMenu:(NSMenu *)menu
                fromNodes:(NSArray<NSDictionary *> *)nodes {
  for (id raw in nodes) {
    if (![raw isKindOfClass:NSDictionary.class])
      continue;
    NSDictionary *node = raw;
    if ([node[@"separator"] boolValue]) {
      [menu addItem:[NSMenuItem separatorItem]];
      continue;
    }
    // "enabled": false trong JSON = tat muc do (va ca menu con cua no).
    id enabled = node[@"enabled"];
    if (enabled != nil && ![enabled boolValue])
      continue;

    NSString *nodeId = node[@"id"];
    if (![nodeId isKindOfClass:NSString.class] || nodeId.length == 0)
      continue;
    if (![self macViKeyNodeEnabled:nodeId])
      continue;

    NSString *title = node[@"title"];
    if (![title isKindOfClass:NSString.class])
      title = @"";
    NSMenuItem *item = [self macViKeyAddNode:nodeId title:title toMenu:menu];
    if (item == nil)
      continue;

    // "hint" trong JSON -> bong huong dan tu hien khi re chuot len muc do.
    id hint = node[@"hint"];
    if ([hint isKindOfClass:NSString.class] && [hint length] > 0)
      item.toolTip = hint;

    id children = node[@"items"];
    if ([children isKindOfClass:NSArray.class] && [children count] > 0) {
      NSMenu *sub = [[NSMenu alloc] initWithTitle:@""];
      [sub setAutoenablesItems:NO];
      [self macViKeyBuildMenu:sub fromNodes:children];
      [menu setSubmenu:sub forItem:item];
    }
  }
}

// Bo 2 dau phan cach dinh nhau / dau / cuoi - hay gap sau khi mot muc bi an.
- (void)macViKeyTrimSeparators:(NSMenu *)menu {
  BOOL previousIsSeparator = YES;
  NSInteger i = 0;
  while (i < menu.numberOfItems) {
    NSMenuItem *item = [menu itemAtIndex:i];
    if (item.hasSubmenu)
      [self macViKeyTrimSeparators:item.submenu];
    if (item.isSeparatorItem && previousIsSeparator) {
      [menu removeItemAtIndex:i];
      continue;
    }
    previousIsSeparator = item.isSeparatorItem;
    i++;
  }
  while (menu.numberOfItems > 0 &&
         [menu itemAtIndex:menu.numberOfItems - 1].isSeparatorItem) {
    [menu removeItemAtIndex:menu.numberOfItems - 1];
  }
}

// Doc thu tu phim chuyen tu cay "settings" trong MenuLayout.json.
//
// Vi sao phai co ham rieng: onSwitchKeySelected: tra cuu theo CHI SO trong
// mnuSwitchKeyValues. Truoc day mang do duoc dung trong luc dung menu, nhung
// phim chuyen khong con tren menu nua - neu khong dung o day thi chi so tu cua
// so Cai dat se tro vao mang rong.
- (void)macViKeyLoadSwitchKeyOrder {
  mnuSwitchKeyValues = [NSMutableArray array];
  mnuSwitchKeyNames = [NSMutableArray array];

  NSDictionary<NSString *, NSNumber *> *values = [self macViKeySwitchKeyValuesById];
  for (id rawPage in [MacViKeyMenuLayout settingsNodes]) {
    if (![rawPage isKindOfClass:NSDictionary.class])
      continue;
    id items = ((NSDictionary *)rawPage)[@"items"];
    if (![items isKindOfClass:NSArray.class])
      continue;
    for (id raw in items) {
      if (![raw isKindOfClass:NSDictionary.class])
        continue;
      NSDictionary *node = raw;
      NSString *nodeId = node[@"id"];
      if (![nodeId isKindOfClass:NSString.class])
        continue;
      NSNumber *value = values[nodeId];
      if (value == nil)
        continue;
      id enabled = node[@"enabled"];
      if (enabled != nil && ![enabled boolValue])
        continue;
      [mnuSwitchKeyValues addObject:value];
      // "short" la ten ngan cho dong thong tin tren menu; thieu thi dung title.
      NSString *name = node[@"short"];
      if (![name isKindOfClass:NSString.class] || name.length == 0) {
        NSString *title = node[@"title"];
        name = [title isKindOfClass:NSString.class] ? title : nodeId;
      }
      [mnuSwitchKeyNames addObject:name];
    }
  }

  if (mnuSwitchKeyValues.count == 0) {
    NSLog(@"[MacViKey] MenuLayout.json khong co muc phim chuyen nao - dung "
          @"to hop mac dinh.");
    [mnuSwitchKeyValues addObject:@(MACVIKEY_SWITCH_DEFAULT)];
    [mnuSwitchKeyNames addObject:@"Control + Shift"];
  }
}

// Ten to hop phim dang dung, cho dong thong tin tren menu.
- (NSString *)macViKeyCurrentSwitchKeyName {
  int current = vSwitchKeyStatus | MACVIKEY_SWITCH_BEEP;
  for (NSInteger i = 0; i < (NSInteger)mnuSwitchKeyValues.count; i++) {
    if ([mnuSwitchKeyValues[i] intValue] == current)
      return mnuSwitchKeyNames[i];
  }
  return mnuSwitchKeyNames.firstObject ?: @"";
}

- (void)createStatusBarMenu {
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];

  theMenu = [[NSMenu alloc] initWithTitle:@""];
  [theMenu setAutoenablesItems:NO];

  [self macViKeyLoadSwitchKeyOrder];

  [self macViKeyBuildMenu:theMenu fromNodes:[MacViKeyMenuLayout nodes]];
  [self macViKeyTrimSeparators:theMenu];

  // MenuLayout.json hong hoac rong: van phai co duong thoat + bat/tat bo go,
  // khong de nguoi dung ket voi mot menu trong.
  if (theMenu.numberOfItems == 0) {
    NSLog(@"[MacViKey] Menu rong - dung menu du phong toi thieu.");
    [self macViKeyAddNode:@"statusLine"
                    title:@"Bật/tắt Tiếng Việt"
                   toMenu:theMenu];
    [self macViKeyAddNode:@"openSettings" title:@"Cài đặt..." toMenu:theMenu];
    [theMenu addItem:[NSMenuItem separatorItem]];
    [self macViKeyAddNode:@"quit" title:@"Thoát" toMenu:theMenu];
  }

  theMenu.delegate = self;
  [statusItem setMenu:theMenu];
  [self macViKeyApplyMenuBarVisibility];

  [self fillData];
}

- (void)loadDefaultConfig {
  vLanguage = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vLanguage
                                             forKey:@"InputMethod"];
  vInputType = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vInputType
                                             forKey:@"InputType"];
  vInputType = MACVIKEY_FIXED_INPUT_TYPE;
  [[NSUserDefaults standardUserDefaults] setInteger:vInputType
                                             forKey:@"InputType"];
  vFreeMark = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vFreeMark
                                             forKey:@"FreeMark"];
  vCheckSpelling = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vCheckSpelling
                                             forKey:@"Spelling"];
  vCodeTable = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vCodeTable
                                             forKey:@"CodeTable"];
  vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
  vQuickTelex = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vQuickTelex
                                             forKey:@"QuickTelex"];
  vUseModernOrthography = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vUseModernOrthography
                                             forKey:@"ModernOrthography"];
  vRestoreIfWrongSpelling = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vRestoreIfWrongSpelling
                                             forKey:@"RestoreIfInvalidWord"];
  vFixRecommendBrowser = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vFixRecommendBrowser
                                             forKey:@"FixRecommendBrowser"];
  vSendKeyStepByStep = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vSendKeyStepByStep
                                             forKey:@"SendKeyStepByStep"];
  vUseSmartSwitchKey = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vUseSmartSwitchKey
                                             forKey:@"UseSmartSwitchKey"];
  vUpperCaseFirstChar = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vUpperCaseFirstChar
                                             forKey:@"UpperCaseFirstChar"];
  vTempOffSpelling = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vTempOffSpelling
                                             forKey:@"vTempOffSpelling"];
  vAllowConsonantZFWJ = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vAllowConsonantZFWJ
                                             forKey:@"vAllowConsonantZFWJ"];
  vQuickStartConsonant = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vQuickStartConsonant
                                             forKey:@"vQuickStartConsonant"];
  vQuickEndConsonant = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vQuickEndConsonant
                                             forKey:@"vQuickEndConsonant"];
  vRememberCode = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vRememberCode
                                             forKey:@"vRememberCode"];
  vRememberCode = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vRememberCode
                                             forKey:@"vRememberCode"];
  vOtherLanguage = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vOtherLanguage
                                             forKey:@"vOtherLanguage"];
  vTempOffEngineByHotKey = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vTempOffEngineByHotKey
                                             forKey:@"vTempOffEngineByHotKey"];
  // Khop voi mac dinh xuat xuong trong applyMacViKeyFixedConfig.
  vShowIconOnDock = 1;
  [[NSUserDefaults standardUserDefaults] setInteger:vShowIconOnDock
                                             forKey:@"vShowIconOnDock"];
  [self showIconOnDock:YES];
  vFixChromiumBrowser = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vFixChromiumBrowser
                                             forKey:@"vFixChromiumBrowser"];
  vPerformLayoutCompat = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vPerformLayoutCompat
                                             forKey:@"vPerformLayoutCompat"];

  // Khôi phục mặc định không được làm sống lại các tuỳ chọn đã bị khoá.
  [self applyMacViKeyFixedConfig];

  [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"GrayIcon"];
  [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"RunOnStartup"];

  [self fillData];
}

// Duong dan file LaunchAgent cho duong macOS < 13.
- (NSString *)macViKeyLaunchAgentPath {
  NSString *dir = [NSHomeDirectory()
      stringByAppendingPathComponent:@"Library/LaunchAgents"];
  return [dir stringByAppendingPathComponent:MACVIKEY_BUNDLE @".plist"];
}

// Khoi dong cung may tren macOS < 13: tu ghi mot LaunchAgent vao
// ~/Library/LaunchAgents.
//
// Vi sao khong dung SMLoginItemSetEnabled: ham do doi mot helper app nam trong
// Contents/Library/LoginItems, ma target helper da bi go khoi project - goi vao
// la that bai AM THAM. LaunchAgent thi khong can helper, va chay tu macOS 11.
//
// Ghi lai plist moi lan bat (chu khong bo qua neu file da ton tai): nguoi dung
// keo app sang cho khac thi Program trong plist cu tro vao duong dan chet.
- (BOOL)macViKeySetLaunchAgentEnabled:(BOOL)val {
  NSString *path = [self macViKeyLaunchAgentPath];
  NSFileManager *fm = [NSFileManager defaultManager];

  if (!val) {
    if (![fm fileExistsAtPath:path])
      return YES;
    NSError *error = nil;
    if ([fm removeItemAtPath:path error:&error])
      return YES;
    NSLog(@"[MacViKey] Khong xoa duoc LaunchAgent: %@", error);
    return NO;
  }

  NSError *error = nil;
  if (![fm createDirectoryAtPath:[path stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error]) {
    NSLog(@"[MacViKey] Khong tao duoc ~/Library/LaunchAgents: %@", error);
    return NO;
  }

  // RunAtLoad: chay khi dang nhap. KeepAlive KHONG bat - nguoi dung chon Thoat
  // thi phai thoat that, khong duoc launchd dung len lai.
  NSDictionary *plist = @{
    @"Label" : MACVIKEY_BUNDLE,
    @"ProgramArguments" : @[ [[NSBundle mainBundle] executablePath] ],
    @"RunAtLoad" : @YES,
    @"KeepAlive" : @NO,
    @"ProcessType" : @"Interactive",
  };
  if ([plist writeToFile:path atomically:YES])
    return YES;
  NSLog(@"[MacViKey] Khong ghi duoc LaunchAgent vao %@", path);
  return NO;
}

// Khoi dong cung may.
//
// Hai duong theo phien ban macOS:
//   - macOS 13+: SMAppService.mainAppService. Day la duong Apple cong nhan, va
//     no hien ra trong Cai dat He thong > Muc dang nhap nen nguoi dung tu tat
//     duoc.
//   - macOS 11-12: tu ghi LaunchAgent. SMAppService chua co o cac ban nay.
//
// Tren 13+ con don them LaunchAgent cu: may nang cap tu 12 len 13 se co CA HAI
// duong cung bat -> app bi khoi chay hai lan moi lan dang nhap.
- (void)setRunOnStartup:(BOOL)val {
  if (@available(macOS 13.0, *)) {
    [self macViKeySetLaunchAgentEnabled:NO];
    SMAppService *service = [SMAppService mainAppService];
    NSError *error = nil;
    BOOL ok = val ? [service registerAndReturnError:&error]
                  : [service unregisterAndReturnError:&error];
    // Da bat san roi thi register tra ve loi - do khong phai that bai.
    if (!ok && !(val && service.status == SMAppServiceStatusEnabled)) {
      NSLog(@"[MacViKey] Khong dat duoc khoi dong cung may (%@): %@",
            val ? @"bat" : @"tat", error);
    }
    return;
  }
  [self macViKeySetLaunchAgentEnabled:val];
}

// An bieu tuong khoi thanh menu.
//
// Van giu statusItem chu khong huy: NSStatusItem.visible = NO chi giau di, bat
// lai la hien ngay, khong phai dung lai toan bo menu.
//
// Duong quay lai khi da an: bam vao MacViKey.app se mo bang nhanh
// (applicationShouldHandleReopen -> onSettingsSelected), trong do co dung
// tuy chon nay de bat tro lai. Khong co duong nay thi an icon la mat luon loi
// vao ung dung.
- (void)macViKeyApplyMenuBarVisibility {
  if (statusItem == nil)
    return;
  statusItem.visible = [self macViKeyOptionIsOn:MacViKeyOptionShowIconOnMenuBar];
}

- (void)setGrayIcon:(BOOL)val {
  [self fillData];
}

- (void)showIconOnDock:(BOOL)val {
  [NSApp setActivationPolicy:val ? NSApplicationActivationPolicyRegular
                                 : NSApplicationActivationPolicyAccessory];
}

#pragma mark -MacViKey: phim chuyen & tuy chon tren menu


- (void)onSwitchKeySelected:(NSMenuItem *)sender {
  if (sender.tag < 0 || sender.tag >= (NSInteger)mnuSwitchKeyValues.count)
    return;
  // Luon bat beep: nguoi dung phai nghe duoc minh vua doi che do.
  vSwitchKeyStatus =
      [mnuSwitchKeyValues[sender.tag] intValue] | MACVIKEY_SWITCH_BEEP;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
  [self fillData];
}

- (NSString *)macViKeyPrefKeyForTag:(NSInteger)tag {
  switch (tag) {
  case MacViKeyOptionFreeMark:
    return @"FreeMark";
  case MacViKeyOptionFixRecommendBrowser:
    return @"FixRecommendBrowser";
  case MacViKeyOptionUpperCaseFirstChar:
    return @"UpperCaseFirstChar";
  case MacViKeyOptionSmartSwitchKey:
    return @"UseSmartSwitchKey";
  case MacViKeyOptionAllowZFWJ:
    return @"vAllowConsonantZFWJ";
  case MacViKeyOptionTempOffEngine:
    return @"vTempOffEngineByHotKey";
  case MacViKeyOptionOtherLanguage:
    return @"vOtherLanguage";
  case MacViKeyOptionRunOnStartup:
    return @"RunOnStartup";
  case MacViKeyOptionShowIconOnDock:
    return @"vShowIconOnDock";
  case MacViKeyOptionGrayIcon:
    return @"GrayIcon";
  case MacViKeyOptionSendKeyStepByStep:
    return @"SendKeyStepByStep";
  case MacViKeyOptionFixChromium:
    return @"vFixChromiumBrowser";
  case MacViKeyOptionLayoutCompat:
    return @"vPerformLayoutCompat";
  case MacViKeyOptionShowUIOnStartup:
    return @"ShowUIOnStartup";
  case MacViKeyOptionShowIconOnMenuBar:
    return @"vShowIconOnMenuBar";
  }
  return nil;
}

- (int *)macViKeyVarForTag:(NSInteger)tag {
  switch (tag) {
  case MacViKeyOptionFreeMark:
    return &vFreeMark;
  case MacViKeyOptionFixRecommendBrowser:
    return &vFixRecommendBrowser;
  case MacViKeyOptionUpperCaseFirstChar:
    return &vUpperCaseFirstChar;
  case MacViKeyOptionSmartSwitchKey:
    return &vUseSmartSwitchKey;
  case MacViKeyOptionAllowZFWJ:
    return &vAllowConsonantZFWJ;
  case MacViKeyOptionTempOffEngine:
    return &vTempOffEngineByHotKey;
  case MacViKeyOptionOtherLanguage:
    return &vOtherLanguage;
  case MacViKeyOptionShowIconOnDock:
    return &vShowIconOnDock;
  case MacViKeyOptionSendKeyStepByStep:
    return &vSendKeyStepByStep;
  case MacViKeyOptionFixChromium:
    return &vFixChromiumBrowser;
  case MacViKeyOptionLayoutCompat:
    return &vPerformLayoutCompat;
  }
  return NULL;
}

// Gia tri hien thi cua tuy chon.
- (BOOL)macViKeyOptionIsOn:(NSInteger)tag {
  return [[NSUserDefaults standardUserDefaults]
             integerForKey:[self macViKeyPrefKeyForTag:tag]]
             ? YES
             : NO;
}

- (void)onOptionToggled:(NSMenuItem *)sender {
  NSInteger tag = sender.tag;
  NSString *key = [self macViKeyPrefKeyForTag:tag];
  if (key == nil)
    return;

  BOOL newValue = ![self macViKeyOptionIsOn:tag];
  [[NSUserDefaults standardUserDefaults] setInteger:newValue ? 1 : 0
                                             forKey:key];

  int *var = [self macViKeyVarForTag:tag];
  if (var != NULL)
    *var = newValue ? 1 : 0;

  // Vai tuy chon can tac dong ngay len he thong.
  if (tag == MacViKeyOptionRunOnStartup) {
    [self setRunOnStartup:newValue];
  } else if (tag == MacViKeyOptionShowIconOnDock) {
    [self showIconOnDock:newValue];
  } else if (tag == MacViKeyOptionShowIconOnMenuBar) {
    [self macViKeyApplyMenuBarVisibility];
  }

  [self fillData];
}

- (void)onCheckNewVersionNow {
  // Callback khac nil = kiem tra do nguoi dung chu dong bam: MacViKeyManager se
  // bao ca ket qua "dang dung ban moi nhat" va ca truong hop that bai, thay vi
  // im lang.
  [MacViKeyManager checkNewVersion:nil
                     callbackFunc:^{
                     }];
}

// Dong bo trang thai dau tich cua phim chuyen va cac tuy chon.
// Dong bo menu va cua so Cai dat voi prefs.
//
// Menu gio chi con dong trang thai va dong thong tin phim chuyen, nen khong con
// dau tich nao phai dong bo - phan viec do da chuyen ca sang cua so Cai dat.
- (void)macViKeyRefreshMenuStates {
  if (mnuSwitchKeyInfo != nil) {
    mnuSwitchKeyInfo.title = [NSString
        stringWithFormat:[MacViKeyMenuLayout string:@"menu.switchKeyInfo.format"
                                          fallback:@"Phím chuyển: %@"],
                         [self macViKeyCurrentSwitchKeyName]];
  }
  [self macViKeyRefreshSettingsWindow];
}

#pragma mark - MacViKey: cua so Cai dat

// Vi sao dung lai chinh MenuLayout.json thay vi dung rieng mot danh sach: menu
// tha xuong va cua so Cai dat phai luon khop nhau ve chu nghia va ve bo loc.
// Doc chung mot file + chung mot bo loc macViKeyNodeEnabled: thi them/bot mot
// muc trong JSON se tu dong co hieu luc, khong the lech.
//
// Phia nay chi dung DANH SACH MO TA (MacViKeyQuickRow); viec ve la cua lop
// SwiftUI trong MacViKeySettingsView.swift. Ranh gioi do co chu y: moi luat
// "muc nao duoc hien, dang gi, tag bao nhieu" nam o day, mot cho duy nhat.

// Dung mot dong mo ta cho mot node trong mot trang. nil = khong hien.
- (MacViKeyQuickRow *)macViKeySettingsRowForNode:(NSDictionary *)node {
  id jsonEnabled = node[@"enabled"];
  if (jsonEnabled != nil && ![jsonEnabled boolValue])
    return nil;

  NSString *nodeId = node[@"id"];
  if (![nodeId isKindOfClass:NSString.class] || nodeId.length == 0)
    return nil;
  if (![self macViKeyNodeEnabled:nodeId])
    return nil;

  NSString *title = node[@"title"];
  if (![title isKindOfClass:NSString.class])
    title = @"";
  NSString *hint = node[@"hint"];
  if (![hint isKindOfClass:NSString.class])
    hint = nil;

  MacViKeyQuickRow *(^make)(MacViKeyQuickRowKind) =
      ^MacViKeyQuickRow *(MacViKeyQuickRowKind kind) {
    MacViKeyQuickRow *row = [MacViKeyQuickRow rowWithKind:kind
                                                    rowId:nodeId
                                                    title:title];
    row.hint = hint;
    return row;
  };

  if ([nodeId isEqualToString:@"statusLine"])
    return make(MacViKeyQuickRowKindStatus);

  if ([nodeId isEqualToString:@"fixedInputType"] ||
      [nodeId isEqualToString:@"fixedCodeTable"])
    return make(MacViKeyQuickRowKindFixedInfo);

  NSNumber *optionTag = [self macViKeyOptionTagsById][nodeId];
  if (optionTag != nil) {
    MacViKeyQuickRow *row = make(MacViKeyQuickRowKindToggle);
    row.tag = optionTag.integerValue;
    row.on = [self macViKeyOptionIsOn:row.tag];
    return row;
  }

  NSNumber *switchValue = [self macViKeySwitchKeyValuesById][nodeId];
  if (switchValue != nil) {
    // Tag phai la chi so trong mnuSwitchKeyValues vi onSwitchKeySelected: tra
    // cuu theo chi so do.
    NSInteger index = [mnuSwitchKeyValues indexOfObject:switchValue];
    if (index == NSNotFound)
      return nil;
    MacViKeyQuickRow *row = make(MacViKeyQuickRowKindRadio);
    row.tag = index;
    row.on = ((vSwitchKeyStatus | MACVIKEY_SWITCH_BEEP) ==
              [switchValue intValue]);
    return row;
  }

  if ([nodeId isEqualToString:@"checkUpdateNow"] ||
      [nodeId isEqualToString:@"resetDefaults"]) {
    MacViKeyQuickRow *row = make(MacViKeyQuickRowKindAction);
    row.destructive = [nodeId isEqualToString:@"resetDefaults"];
    return row;
  }

  NSLog(@"[MacViKey] MenuLayout.json: khong biet muc \"%@\", bo qua.", nodeId);
  return nil;
}

#pragma mark - MacViKeySettingsActions

- (NSArray<MacViKeyQuickRow *> *)settingsPages {
  NSMutableArray<MacViKeyQuickRow *> *pages = [NSMutableArray array];

  for (id rawPage in [MacViKeyMenuLayout settingsNodes]) {
    if (![rawPage isKindOfClass:NSDictionary.class])
      continue;
    NSDictionary *pageNode = rawPage;

    id enabled = pageNode[@"enabled"];
    if (enabled != nil && ![enabled boolValue])
      continue;
    NSString *pageId = pageNode[@"id"];
    if (![pageId isKindOfClass:NSString.class] || pageId.length == 0)
      continue;

    NSString *title = pageNode[@"title"];
    if (![title isKindOfClass:NSString.class])
      title = @"";
    NSString *hint = pageNode[@"hint"];
    if (![hint isKindOfClass:NSString.class])
      hint = nil;
    NSString *symbol = pageNode[@"symbol"];
    if (![symbol isKindOfClass:NSString.class])
      symbol = nil;

    // Trang Gioi thieu do SwiftUI tu ve, khong sinh tu "items".
    BOOL isAbout = [pageId isEqualToString:@"page.about"];

    NSMutableArray<MacViKeyQuickRow *> *rows = [NSMutableArray array];
    if (!isAbout) {
      id items = pageNode[@"items"];
      if ([items isKindOfClass:NSArray.class]) {
        for (id raw in items) {
          if (![raw isKindOfClass:NSDictionary.class])
            continue;
          MacViKeyQuickRow *row = [self macViKeySettingsRowForNode:raw];
          if (row)
            [rows addObject:row];
        }
      }
      // Ca trang bi tat -> khong ve muc tro tro trong thanh ben.
      if (rows.count == 0)
        continue;
    }

    MacViKeyQuickRow *page = [MacViKeyQuickRow
        rowWithKind:isAbout ? MacViKeyQuickRowKindAboutPage
                            : MacViKeyQuickRowKindPage
              rowId:pageId
              title:title];
    page.hint = hint;
    page.symbol = symbol;
    page.children = rows;
    [pages addObject:page];
  }

  return pages;
}

- (NSString *)settingsStatusTitle {
  if (!MJAccessibilityIsEnabled())
    return [MacViKeyMenuLayout string:@"statusLine.noPermission"
                            fallback:@"Chưa có quyền Trợ năng"];
  if (!MacViKeyIsEventTapAlive())
    return [MacViKeyMenuLayout string:@"statusLine.stopped"
                            fallback:@"Bộ gõ đã dừng"];
  if (_macViKeyTapDisabledCount > 0) {
    return [NSString
        stringWithFormat:[MacViKeyMenuLayout
                             string:@"engineStatus.running.recovered.format"
                           fallback:@"Đang hoạt động (đã tự khôi phục %d lần)"],
                         _macViKeyTapDisabledCount];
  }
  return [MacViKeyMenuLayout string:@"engineStatus.running"
                          fallback:@"Đang hoạt động"];
}

- (BOOL)settingsVietnameseIsOn {
  return [[NSUserDefaults standardUserDefaults]
             integerForKey:@"InputMethod"] == 1;
}

- (BOOL)settingsEngineIsRunning {
  return MJAccessibilityIsEnabled() && MacViKeyIsEventTapAlive();
}

- (void)settingsSetVietnamese:(BOOL)on {
  if ([self settingsVietnameseIsOn] == on)
    return;
  // Dung lai onInputMethodSelected de duong doi che do chi co MOT ban: no con
  // lo beep, nho che do theo ung dung va cap nhat menu.
  [self onInputMethodSelected];
}

- (void)settingsRestartEngine {
  [self onRestartEngine];
}

- (void)settingsToggleOptionWithTag:(NSInteger)tag {
  // onOptionToggled: chi doc sender.tag, nen dung mot NSMenuItem tam la du -
  // khong phai nhan ban logic bat/tat.
  NSMenuItem *proxy = [[NSMenuItem alloc] init];
  proxy.tag = tag;
  [self onOptionToggled:proxy];
}

- (void)settingsSelectSwitchKeyAtIndex:(NSInteger)index {
  NSMenuItem *proxy = [[NSMenuItem alloc] init];
  proxy.tag = index;
  [self onSwitchKeySelected:proxy];
}

- (void)settingsRunActionWithId:(NSString *)rowId {
  if ([rowId isEqualToString:@"checkUpdateNow"]) {
    [self onCheckNewVersionNow];
  } else if ([rowId isEqualToString:@"resetDefaults"]) {
    // loadDefaultConfig goi fillData nen cua so tu dong dong bo lai.
    [self loadDefaultConfig];
  }
}

// Dong bo cua so Cai dat voi prefs. Duoc goi tu fillData nen cua so, menu va
// prefs khong bao gio lech nhau.
- (void)macViKeyRefreshSettingsWindow {
  [_settingsWindow refresh];
}

- (void)onSettingsSelected {
  if (_settingsWindow == nil)
    _settingsWindow = [[MacViKeySettingsWindow alloc] initWithActions:self];
  [_settingsWindow show];
}

#pragma mark -StatusBar menu data

- (void)fillData {
  NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

  // Bieu tuong tren thanh menu: CHI chu VI / EN.
  //
  // Bo logo di vi tren thanh menu logo mau khong giup nhan ra app nhanh hon hai
  // chu viet hoa, ma con chiem cho va bi ep ve 18pt thanh mot vet nhoe.
  NSInteger intInputMethod = [prefs integerForKey:@"InputMethod"];
  statusItem.button.image = nil;
  statusItem.button.alternateImage = nil;
  statusItem.button.imagePosition = NSNoImage;
  statusItem.button.font =
      [NSFont monospacedDigitSystemFontOfSize:[NSFont systemFontSize]
                                       weight:NSFontWeightBold];
  statusItem.button.title =
      (intInputMethod == 1)
          ? [MacViKeyMenuLayout string:@"statusBar.vi" fallback:@"VI"]
          : [MacViKeyMenuLayout string:@"statusBar.en" fallback:@"EN"];
  vLanguage = (int)intInputMethod;

  // Kieu go va bang ma da khoa cung: ep lai gia tri, khong con muc menu nao
  // phai danh dau.
  vInputType = MACVIKEY_FIXED_INPUT_TYPE;
  [prefs setInteger:vInputType forKey:@"InputType"];
  vCodeTable = MACVIKEY_FIXED_CODE_TABLE;
  [prefs setInteger:vCodeTable forKey:@"CodeTable"];

  vSwitchKeyStatus = (int)[prefs integerForKey:@"SwitchKeyStatus"];
  if (![self macViKeyIsSupportedSwitchKey:vSwitchKeyStatus])
    vSwitchKeyStatus = MACVIKEY_SWITCH_DEFAULT;
  vSwitchKeyStatus |= MACVIKEY_SWITCH_BEEP;
  [prefs setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];

  [self setRunOnStartup:[prefs integerForKey:@"RunOnStartup"] ? YES : NO];

  [self macViKeyUpdateStatusLine];
  [self macViKeyRefreshMenuStates];
}

- (void)onImputMethodChanged:(BOOL)willNotify {
  NSInteger intInputMethod =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
  if (intInputMethod == 0)
    intInputMethod = 1;
  else
    intInputMethod = 0;
  vLanguage = (int)intInputMethod;
  [[NSUserDefaults standardUserDefaults] setInteger:intInputMethod
                                             forKey:@"InputMethod"];

  [self fillData];

  if (willNotify)
    OnInputMethodChanged();
}

#pragma mark -MacViKey: watchdog event tap

// Duong chinh de khoi phuc tap la ngay trong MacViKeyCallback (bat su kien
// kCGEventTapDisabledByTimeout). Watchdog nay la lop bao ve thu hai, cho cac
// truong hop tap chet am tham: sau khi may thuc day, quyen Accessibility bi
// thu hoi, hoac WindowServer khoi dong lai.
- (void)startTapWatchdog {
  [_tapWatchdog invalidate];
  _tapWatchdog =
      [NSTimer scheduledTimerWithTimeInterval:5.0
                                       target:self
                                     selector:@selector(checkTapHealth)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)checkTapHealth {
  if (![MacViKeyManager isInited])
    return;
  BOOL alive = MacViKeyIsEventTapAlive();
  if (!alive) {
    NSLog(@"[MacViKey] Watchdog: event tap da chet, dang khoi phuc...");
    if (!MacViKeyReenableEventTap()) {
      // Bat lai that bai -> dung han tap cu roi tao moi.
      [MacViKeyManager stopEventTap];
      [MacViKeyManager initEventTap];
    }
  }
  [self macViKeyUpdateStatusLine];
}

/// Bong huong dan cua dong trang thai: ten, phien ban va tinh trang bo go.
- (NSString *)macViKeyStatusLineHint {
  NSString *engine;
  if (!MJAccessibilityIsEnabled()) {
    engine = [MacViKeyMenuLayout string:@"statusLine.hint.noPermission"
                               fallback:@"chưa có quyền Trợ năng"];
  } else if (!MacViKeyIsEventTapAlive()) {
    engine = [MacViKeyMenuLayout string:@"statusLine.hint.stopped"
                               fallback:@"bộ gõ đã dừng"];
  } else if (_macViKeyTapDisabledCount > 0) {
    engine =
        [NSString stringWithFormat:
                      [MacViKeyMenuLayout
                            string:@"engineStatus.running.recovered.format"
                          fallback:@"Đang hoạt động (đã tự khôi phục %d lần)"],
                      _macViKeyTapDisabledCount];
  } else {
    engine = [MacViKeyMenuLayout string:@"engineStatus.running"
                               fallback:@"Đang hoạt động"];
  }
  NSString *format = [MacViKeyMenuLayout string:@"statusLine.hint.format"
                                       fallback:@"%@ v%@ — %@"];
  return [NSString stringWithFormat:format, MacViKeyInfo.appName,
                                    MacViKeyInfo.versionString, engine];
}

/// Mot dong lo ca hai viec: bao trang thai bo go va bat/tat tieng Viet.
/// Chua co quyen Tro nang thi viec duy nhat dang lam la XIN QUYEN - luc do
/// khong bay ra lua chon Viet/Anh nua cho khoi roi.
- (void)macViKeyUpdateStatusLine {
  if (mnuStatusLine == nil)
    return;
  mnuStatusLine.toolTip = [self macViKeyStatusLineHint];

  if (!MJAccessibilityIsEnabled()) {
    [self macViKeySetTitle:[MacViKeyMenuLayout
                                 string:@"statusLine.noPermission"
                               fallback:@"⚠️ Chưa có quyền Trợ năng — bấm "
                                        @"để cấp quyền"]
                   forItem:mnuStatusLine];
    [mnuStatusLine setState:NSControlStateValueOff];
    return;
  }
  if (!MacViKeyIsEventTapAlive()) {
    [self macViKeySetTitle:[MacViKeyMenuLayout
                                 string:@"statusLine.stopped"
                               fallback:@"⚠️ Bộ gõ đã dừng — bấm để khởi "
                                        @"động lại"]
                   forItem:mnuStatusLine];
    [mnuStatusLine setState:NSControlStateValueOff];
    return;
  }

  BOOL vietnamese = ([[NSUserDefaults standardUserDefaults]
                         integerForKey:@"InputMethod"] == 1);
  NSString *on =
      [MacViKeyMenuLayout string:@"inputMethod.on.textOnly"
                        fallback:@"Đang TIẾNG VIỆT - bấm chuyển sang English"];
  NSString *off =
      [MacViKeyMenuLayout string:@"inputMethod.off.textOnly"
                        fallback:@"Đang ENGLISH - bấm chuyển sang Tiếng Việt"];
  [self macViKeySetTitle:vietnamese ? on : off forItem:mnuStatusLine];
  [mnuStatusLine
      setState:vietnamese ? NSControlStateValueOn : NSControlStateValueOff];
}

/// Bam vao dong trang thai: lam viec dang can nhat tai thoi diem do.
- (void)onStatusLineClicked {
  if (!MJAccessibilityIsEnabled()) {
    MJAccessibilityOpenPanel();
    return;
  }
  if (!MacViKeyIsEventTapAlive()) {
    [self onRestartEngine];
    return;
  }
  [self onInputMethodSelected];
}

- (void)onRestartEngine {
  if (!MJAccessibilityIsEnabled()) {
    MJAccessibilityOpenPanel();
    return;
  }
  [MacViKeyManager stopEventTap];
  if ([MacViKeyManager initEventTap]) {
    [self macViKeyUpdateStatusLine];
  } else {
    [MacViKeyManager showMessage:nil
                         message:@"Không khởi động lại được bộ gõ!"
                          subMsg:@"Hãy kiểm tra quyền Trợ năng (Accessibility) "
                                 @"trong Cài đặt Hệ thống."];
  }
}

// Cac muc menu phu thuoc trang thai -> cap nhat ngay truoc khi menu mo ra.
- (void)refreshDynamicMenu {
  [self macViKeyRefreshMenuStates];
  [self macViKeyUpdateStatusLine];
}

- (void)menuWillOpen:(NSMenu *)menu {
  [self refreshDynamicMenu];
}

#pragma mark -StatusBar menu action
- (void)onInputMethodSelected {
  [self onImputMethodChanged:YES];
}

- (void)onCodeTableChanged:(int)index {
  index = MACVIKEY_FIXED_CODE_TABLE;
  [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CodeTable"];
  vCodeTable = index;
  [self fillData];
  OnTableCodeChange();
}


#pragma mark -Short key event
- (void)onSwitchLanguage {
  [self onInputMethodSelected];
}

#pragma mark Reset engine after mac computer awake
- (void)receiveWakeNote:(NSNotification *)note {
  [MacViKeyManager initEventTap];
  // Sau khi thuc day, tap rat hay chet am tham -> ep kiem tra ngay.
  [self checkTapHealth];
}

- (void)receiveSleepNote:(NSNotification *)note {
  [MacViKeyManager stopEventTap];
}

- (void)receiveActiveSpaceChanged:(NSNotification *)note {
  RequestNewSession();
}

- (void)activeAppChanged:(NSNotification *)note {
  if (vUseSmartSwitchKey && [MacViKeyManager isInited]) {
    OnActiveAppChanged();
  }
}

- (void)registerSupportedNotification {
  [[[NSWorkspace sharedWorkspace] notificationCenter]
      addObserver:self
         selector:@selector(receiveWakeNote:)
             name:NSWorkspaceDidWakeNotification
           object:NULL];

  [[[NSWorkspace sharedWorkspace] notificationCenter]
      addObserver:self
         selector:@selector(receiveSleepNote:)
             name:NSWorkspaceWillSleepNotification
           object:NULL];

  [[[NSWorkspace sharedWorkspace] notificationCenter]
      addObserver:self
         selector:@selector(receiveActiveSpaceChanged:)
             name:NSWorkspaceActiveSpaceDidChangeNotification
           object:NULL];

  [[[NSWorkspace sharedWorkspace] notificationCenter]
      addObserver:self
         selector:@selector(activeAppChanged:)
             name:NSWorkspaceDidActivateApplicationNotification
           object:NULL];
}
@end
