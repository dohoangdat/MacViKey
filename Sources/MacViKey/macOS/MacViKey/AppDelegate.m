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
#import "ViewController.h"
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#include <libproc.h>
#include <sys/proc_info.h>

AppDelegate *appDelegate;

// MacViKey: giam sat suc khoe event tap
extern BOOL MacViKeyIsEventTapAlive(void);
extern BOOL MacViKeyReenableEventTap(void);
extern int _macViKeyTapDisabledCount;

// MacViKey: loai tru ung dung + duong Accessibility
extern NSString *MacViKeyCurrentAppName(void);
extern ViewController *viewController;
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

int vShowIconOnDock = 0; // new on version 2.0

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

@interface AppDelegate ()

@end

@implementation AppDelegate {
  NSWindowController *_mainWC;
  NSWindowController *_aboutWC;

  NSStatusItem *statusItem;

  // MacViKey: bang nhanh - ban cua so cua chinh menu tren thanh trang thai.
  NSWindow *_quickWindow;
  NSStackView *_quickStack;
  NSButton *_quickStatusButton;
  NSMutableArray<NSButton *> *_quickOptionButtons;
  NSMutableArray<NSButton *> *_quickSwitchButtons;
  NSMenu *theMenu;

  // Dong dau menu: gop trang thai bo go + bat/tat tieng Viet.
  NSMenuItem *mnuStatusLine;

  NSMenuItem *mnuTelex;
  NSMenuItem *mnuVNI;
  NSMenuItem *mnuSimpleTelex1;
  NSMenuItem *mnuSimpleTelex2;

  NSMenuItem *mnuUnicode;
  NSMenuItem *mnuTCVN;
  NSMenuItem *mnuVNIWindows;

  NSMenuItem *mnuUnicodeComposite;
  NSMenuItem *mnuVietnameseLocaleCP1258;


  // MacViKey
  NSTimer *_permissionPoll;
  NSTimer *_tapWatchdog;

  // MacViKey: phim chuyen + toan bo tuy chon nay gio nam tren menu thanh trang
  // thai.
  NSMutableArray<NSMenuItem *> *mnuSwitchKeyItems;
  NSMutableArray<NSNumber *> *mnuSwitchKeyValues;
  NSMutableArray<NSMenuItem *> *mnuOptionItems;
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
  [prefs registerDefaults:@{@"RunOnStartup" : @1, @"vShowIconOnMenuBar" : @1}];
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

  // check if user granted Accessabilty permission
  if (!MJAccessibilityIsEnabled()) {
    vShowIconOnDock = (int)[[NSUserDefaults standardUserDefaults]
        integerForKey:@"vShowIconOnDock"];
    [self askPermission];
    return; // askPermission se tu khoi dong bo go khi quyen duoc cap
  }

  vShowIconOnDock = (int)[[NSUserDefaults standardUserDefaults]
      integerForKey:@"vShowIconOnDock"];
  if (vShowIconOnDock)
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

  if (vSwitchKeyStatus & 0x8000)
    NSBeep();

  [self createStatusBarMenu];

  // init
  dispatch_async(dispatch_get_main_queue(), ^{
    if (![MacViKeyManager initEventTap]) {
      [self onControlPanelSelected];
    } else {
      NSInteger showui = [[NSUserDefaults standardUserDefaults]
          integerForKey:@"ShowUIOnStartup"];
      if (showui == 1) {
        [self onControlPanelSelected];
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

// Click vao .app khi app da chay: mo bang nhanh - ban cua so cua chinh menu
// tren thanh trang thai. Bang dieu khien cu gio chi con mot tab thong tin va
// khong chinh duoc gi, mo no ra khong giup gi cho nguoi dung.
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender
                    hasVisibleWindows:(BOOL)flag {
  [self onQuickPanelSelected];
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

/// Doi dau tick mac dinh cua macOS sang logo MacViKey: muc dang bat thi co
/// logo o truoc. Muc chua chon de trong cho menu do roi mat.
- (void)macViKeyUseCheckboxGlyph:(NSMenuItem *)item {
  static NSImage *onImage = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    // Cot dau tich hep hon cot anh cua menu item -> logo de nho hon 16pt.
    onImage = [self macViKeyMenuLogoImageOfSize:14];
  });
  item.onStateImage = onImage;
  item.offStateImage = nil;
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
    [set addObjectsFromArray:@[
      @"inputTypeMenu", @"codeMenu", @"code.unicode", @"code.tcvn3",
      @"code.vniWindows"
    ]];
    [set addObject:@"controlPanel"];
    // Toan bo tuy chon go da bi khoa cung trong MacViKeyInit() -> an ca menu
    // cha lan cac muc con. Ba muc sua loi ben menu "He thong" cung vay.
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
- (NSMenuItem *)macViKeyAddNode:(NSString *)nodeId
                          title:(NSString *)title
                         toMenu:(NSMenu *)menu {
  NSNumber *optionTag = [self macViKeyOptionTagsById][nodeId];
  if (optionTag != nil) {
    NSMenuItem *item = [menu addItemWithTitle:title
                                       action:@selector(onOptionToggled:)
                                keyEquivalent:@""];
    item.tag = optionTag.integerValue;
    [mnuOptionItems addObject:item];
    [self macViKeyUseCheckboxGlyph:item];
    return item;
  }

  NSNumber *switchValue = [self macViKeySwitchKeyValuesById][nodeId];
  if (switchValue != nil) {
    NSMenuItem *item = [menu addItemWithTitle:title
                                       action:@selector(onSwitchKeySelected:)
                                keyEquivalent:@""];
    item.tag = (NSInteger)mnuSwitchKeyItems.count;
    [mnuSwitchKeyItems addObject:item];
    [mnuSwitchKeyValues addObject:switchValue];
    [self macViKeyUseCheckboxGlyph:item];
    return item;
  }

  // Menu cha: khong co hanh dong, chi de chua menu con.
  if ([nodeId isEqualToString:@"inputTypeMenu"] ||
      [nodeId isEqualToString:@"codeMenu"] ||
      [nodeId isEqualToString:@"switchKeyMenu"] ||
      [nodeId isEqualToString:@"typingOptionsMenu"] ||
      [nodeId isEqualToString:@"systemOptionsMenu"]) {
    return [menu addItemWithTitle:title action:nil keyEquivalent:@""];
  }

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
    [self macViKeyUseCheckboxGlyph:mnuStatusLine];
    return mnuStatusLine;
  }

  // Kieu go + bang ma da bi khoa: hien dang thong tin, khong bam duoc.
  if ([nodeId isEqualToString:@"fixedInputType"]) {
    mnuSimpleTelex1 = [menu addItemWithTitle:title
                                      action:nil
                               keyEquivalent:@""];
    mnuSimpleTelex1.tag = MACVIKEY_FIXED_INPUT_TYPE;
    [mnuSimpleTelex1 setEnabled:NO];
    [mnuSimpleTelex1 setState:NSControlStateValueOn];
    [self macViKeyUseCheckboxGlyph:mnuSimpleTelex1];
    return mnuSimpleTelex1;
  }
  if ([nodeId isEqualToString:@"fixedCodeTable"]) {
    mnuUnicode = [menu addItemWithTitle:title action:nil keyEquivalent:@""];
    mnuUnicode.tag = MACVIKEY_FIXED_CODE_TABLE;
    [mnuUnicode setEnabled:NO];
    [mnuUnicode setState:NSControlStateValueOn];
    [self macViKeyUseCheckboxGlyph:mnuUnicode];
    return mnuUnicode;
  }

  // Kieu go: tag phai khop vInputType.
  NSDictionary<NSString *, NSNumber *> *inputTypes = @{
    @"inputType.telex" : @0,
    @"inputType.vni" : @1,
    @"inputType.simpleTelex1" : @2,
    @"inputType.simpleTelex2" : @3,
  };
  NSNumber *inputTypeTag = inputTypes[nodeId];
  if (inputTypeTag != nil) {
    NSMenuItem *item = [menu addItemWithTitle:title
                                       action:@selector(onInputTypeSelected:)
                                keyEquivalent:@""];
    item.tag = inputTypeTag.integerValue;
    switch (inputTypeTag.intValue) {
    case 0:
      mnuTelex = item;
      break;
    case 1:
      mnuVNI = item;
      break;
    case 2:
      mnuSimpleTelex1 = item;
      break;
    default:
      mnuSimpleTelex2 = item;
      break;
    }
    return item;
  }

  // Bang ma: tag phai khop vCodeTable.
  NSDictionary<NSString *, NSNumber *> *codeTables = @{
    @"code.unicode" : @0,
    @"code.tcvn3" : @1,
    @"code.vniWindows" : @2,
    @"code.unicodeComposite" : @3,
    @"code.cp1258" : @4,
  };
  NSNumber *codeTag = codeTables[nodeId];
  if (codeTag != nil) {
    NSMenuItem *item = [menu addItemWithTitle:title
                                       action:@selector(onCodeSelected:)
                                keyEquivalent:@""];
    item.tag = codeTag.integerValue;
    switch (codeTag.intValue) {
    case 0:
      mnuUnicode = item;
      break;
    case 1:
      mnuTCVN = item;
      break;
    case 2:
      mnuVNIWindows = item;
      break;
    case 3:
      mnuUnicodeComposite = item;
      break;
    default:
      mnuVietnameseLocaleCP1258 = item;
      break;
    }
    return item;
  }

  if ([nodeId isEqualToString:@"controlPanel"]) {
    return [menu addItemWithTitle:title
                           action:@selector(onControlPanelSelected)
                    keyEquivalent:@""];
  }
  if ([nodeId isEqualToString:@"about"]) {
    return [menu addItemWithTitle:title
                           action:@selector(onAboutSelected)
                    keyEquivalent:@""];
  }
  if ([nodeId isEqualToString:@"checkUpdateNow"]) {
    return [menu addItemWithTitle:title
                           action:@selector(onCheckNewVersionNow)
                    keyEquivalent:@""];
  }
  if ([nodeId isEqualToString:@"quit"]) {
    return [menu addItemWithTitle:title
                           action:@selector(terminate:)
                    keyEquivalent:@"q"];
  }

  NSLog(@"[MacViKey] MenuLayout.json: khong biet muc \"%@\", bo qua.", nodeId);
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

- (void)createStatusBarMenu {
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];

  theMenu = [[NSMenu alloc] initWithTitle:@""];
  [theMenu setAutoenablesItems:NO];

  mnuSwitchKeyItems = [NSMutableArray array];
  mnuSwitchKeyValues = [NSMutableArray array];
  mnuOptionItems = [NSMutableArray array];

  [self macViKeyBuildMenu:theMenu fromNodes:[MacViKeyMenuLayout nodes]];
  [self macViKeyTrimSeparators:theMenu];

  // MenuLayout.json hong hoac rong: van phai co duong thoat + bat/tat bo go,
  // khong de nguoi dung ket voi mot menu trong.
  if (theMenu.numberOfItems == 0) {
    NSLog(@"[MacViKey] Menu rong - dung menu du phong toi thieu.");
    [self macViKeyAddNode:@"inputMethod"
                    title:@"Bật/tắt Tiếng Việt"
                   toMenu:theMenu];
    [self macViKeyAddNode:@"engineStatus" title:@"" toMenu:theMenu];
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
  vShowIconOnDock = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:vShowIconOnDock
                                             forKey:@"vShowIconOnDock"];
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
  [viewController fillData];
}

// Khoi dong cung may.
//
// Ban goc dung SMLoginItemSetEnabled voi mot helper rieng nam trong
// Contents/Library/LoginItems. Target helper da bi go khoi project, nen loi goi
// do luon that bai AM THAM: prefs ghi RunOnStartup = 1 ma app khong bao gio tu
// chay.
//
// SMAppService.mainAppService dang ky chinh app lam login item, khong can
// helper - nhung chi co tu macOS 13. Duoi nguong do khong con duong nao dung
// duoc: helper da khong ton tai, SMLoginItemSetEnabled se that bai am tham.
// Nen o day ghi log ro rang thay vi im lang - im lang la dung cai bug vua sua.
- (void)setRunOnStartup:(BOOL)val {
  if (@available(macOS 13.0, *)) {
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
  NSLog(@"[MacViKey] Khoi dong cung may can macOS 13 tro len; ban macOS nay "
        @"khong ho tro.");
}

// An bieu tuong khoi thanh menu.
//
// Van giu statusItem chu khong huy: NSStatusItem.visible = NO chi giau di, bat
// lai la hien ngay, khong phai dung lai toan bo menu.
//
// Duong quay lai khi da an: bam vao MacViKey.app se mo bang nhanh
// (applicationShouldHandleReopen -> onQuickPanelSelected), trong do co dung
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
  [viewController fillData];
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
  [viewController fillData];
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
- (void)macViKeyRefreshMenuStates {
  [self macViKeyRefreshQuickPanel];
  for (NSInteger i = 0; i < (NSInteger)mnuSwitchKeyItems.count; i++) {
    BOOL on = ((vSwitchKeyStatus | MACVIKEY_SWITCH_BEEP) ==
               [mnuSwitchKeyValues[i] intValue]);
    [mnuSwitchKeyItems[i]
        setState:on ? NSControlStateValueOn : NSControlStateValueOff];
  }
  for (NSMenuItem *item in mnuOptionItems) {
    [item setState:[self macViKeyOptionIsOn:item.tag] ? NSControlStateValueOn
                                                      : NSControlStateValueOff];
  }
}

#pragma mark - MacViKey: bang nhanh (ban cua so cua menu thanh trang thai)

// Vi sao dung lai chinh MenuLayout.json thay vi dung rieng mot danh sach: bang
// nhanh va menu tren thanh trang thai phai luon khop nhau. Doc chung mot cay
// node + chung mot bo loc macViKeyNodeEnabled: thi them/bot mot muc trong JSON
// se tu dong hien o ca hai noi, khong the lech.
//
// Cac nut cung tro thang vao action cua menu (onOptionToggled:,
// onSwitchKeySelected:) - hai ham do chi doc sender.tag, ma NSButton cung co
// tag, nen khong can nhan ban logic.

static const CGFloat kQuickWidth = 340.0;

- (NSTextField *)macViKeyQuickLabel:(NSString *)text bold:(BOOL)bold {
  NSTextField *label = [NSTextField labelWithString:text];
  label.font = bold ? [NSFont boldSystemFontOfSize:11]
                    : [NSFont systemFontOfSize:NSFont.systemFontSize];
  if (bold)
    label.textColor = [NSColor secondaryLabelColor];
  return label;
}

- (NSBox *)macViKeyQuickSeparator {
  NSBox *box = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, kQuickWidth, 1)];
  box.boxType = NSBoxSeparator;
  return box;
}

// Dung mot dong cho mot node. Tra nil = node nay khong hien tren bang nhanh.
- (NSView *)macViKeyQuickRowForNode:(NSDictionary *)node {
  if ([node[@"separator"] boolValue])
    return [self macViKeyQuickSeparator];

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

  // Node cha: tieu de nhom + cac dong con thut vao.
  id children = node[@"items"];
  if ([children isKindOfClass:NSArray.class] && [children count] > 0) {
    NSMutableArray<NSView *> *rows = [NSMutableArray array];
    for (id raw in children) {
      if (![raw isKindOfClass:NSDictionary.class])
        continue;
      NSView *row = [self macViKeyQuickRowForNode:raw];
      if (row)
        [rows addObject:row];
    }
    if (rows.count == 0)
      return nil; // ca nhom bi tat -> khong ve tieu de tro tro

    NSStackView *group = [NSStackView stackViewWithViews:rows];
    group.orientation = NSUserInterfaceLayoutOrientationVertical;
    group.alignment = NSLayoutAttributeLeading;
    group.spacing = 6;
    group.edgeInsets = NSEdgeInsetsMake(0, 16, 0, 0);

    NSStackView *section = [NSStackView
        stackViewWithViews:@[ [self macViKeyQuickLabel:title.uppercaseString
                                                  bold:YES],
                              group ]];
    section.orientation = NSUserInterfaceLayoutOrientationVertical;
    section.alignment = NSLayoutAttributeLeading;
    section.spacing = 6;
    return section;
  }

  // Dong trang thai: nut lon, la thu nguoi dung bam nhieu nhat.
  if ([nodeId isEqualToString:@"statusLine"] ||
      [nodeId isEqualToString:@"inputMethod"] ||
      [nodeId isEqualToString:@"engineStatus"]) {
    if (_quickStatusButton != nil)
      return nil;
    NSButton *button = [NSButton buttonWithTitle:title
                                          target:self
                                          action:@selector(onStatusLineClicked)];
    button.bezelStyle = NSBezelStyleRounded;
    // NSControlSizeLarge chi co tu macOS 11; duoi nguong do giu co mac dinh.
    if (@available(macOS 11.0, *))
      button.controlSize = NSControlSizeLarge;
    [button.widthAnchor constraintEqualToConstant:kQuickWidth].active = YES;
    _quickStatusButton = button;
    return button;
  }

  // Kieu go / bang ma da khoa cung: chi la thong tin, khong bam duoc.
  if ([nodeId isEqualToString:@"fixedInputType"] ||
      [nodeId isEqualToString:@"fixedCodeTable"]) {
    NSButton *check = [NSButton checkboxWithTitle:title target:nil action:nil];
    check.state = NSControlStateValueOn;
    check.enabled = NO;
    return check;
  }

  NSNumber *optionTag = [self macViKeyOptionTagsById][nodeId];
  if (optionTag != nil) {
    NSButton *check = [NSButton checkboxWithTitle:title
                                           target:self
                                           action:@selector(onOptionToggled:)];
    check.tag = optionTag.integerValue;
    [_quickOptionButtons addObject:check];
    return check;
  }

  NSNumber *switchValue = [self macViKeySwitchKeyValuesById][nodeId];
  if (switchValue != nil) {
    // Tag phai la chi so trong mnuSwitchKeyValues vi onSwitchKeySelected: tra
    // cuu theo chi so do. Menu luon dung truoc bang nhanh nen mang da san sang.
    NSInteger index = [mnuSwitchKeyValues indexOfObject:switchValue];
    if (index == NSNotFound)
      return nil;
    NSButton *radio = [NSButton radioButtonWithTitle:title
                                              target:self
                                              action:@selector
                                              (onSwitchKeySelected:)];
    radio.tag = index;
    [_quickSwitchButtons addObject:radio];
    return radio;
  }

  if ([nodeId isEqualToString:@"checkUpdateNow"]) {
    return [NSButton buttonWithTitle:title
                              target:self
                              action:@selector(onCheckNewVersionNow)];
  }
  if ([nodeId isEqualToString:@"about"]) {
    return [NSButton buttonWithTitle:title
                              target:self
                              action:@selector(onAboutSelected)];
  }
  if ([nodeId isEqualToString:@"controlPanel"]) {
    return [NSButton buttonWithTitle:title
                              target:self
                              action:@selector(onControlPanelSelected)];
  }
  if ([nodeId isEqualToString:@"quit"]) {
    return [NSButton buttonWithTitle:title
                              target:NSApp
                              action:@selector(terminate:)];
  }
  return nil;
}

- (void)macViKeyBuildQuickPanel {
  _quickOptionButtons = [NSMutableArray array];
  _quickSwitchButtons = [NSMutableArray array];
  _quickStatusButton = nil;

  NSMutableArray<NSView *> *rows = [NSMutableArray array];
  for (id raw in [MacViKeyMenuLayout nodes]) {
    if (![raw isKindOfClass:NSDictionary.class])
      continue;
    NSView *row = [self macViKeyQuickRowForNode:raw];
    if (row)
      [rows addObject:row];
  }
  // Bo duong ke dinh nhau / dau / cuoi - y het macViKeyTrimSeparators.
  NSMutableArray<NSView *> *trimmed = [NSMutableArray array];
  BOOL previousIsSeparator = YES;
  for (NSView *row in rows) {
    BOOL isSeparator = [row isKindOfClass:NSBox.class];
    if (isSeparator && previousIsSeparator)
      continue;
    [trimmed addObject:row];
    previousIsSeparator = isSeparator;
  }
  while (trimmed.count > 0 && [trimmed.lastObject isKindOfClass:NSBox.class])
    [trimmed removeLastObject];

  _quickStack = [NSStackView stackViewWithViews:trimmed];
  _quickStack.orientation = NSUserInterfaceLayoutOrientationVertical;
  _quickStack.alignment = NSLayoutAttributeLeading;
  _quickStack.spacing = 10;
  _quickStack.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20);
  _quickStack.translatesAutoresizingMaskIntoConstraints = NO;

  NSView *content = [[NSView alloc] initWithFrame:NSZeroRect];
  [content addSubview:_quickStack];
  [NSLayoutConstraint activateConstraints:@[
    [_quickStack.topAnchor constraintEqualToAnchor:content.topAnchor],
    [_quickStack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
    [_quickStack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
    [_quickStack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
  ]];

  _quickWindow = [NSWindow
      windowWithContentViewController:({
        NSViewController *vc = [[NSViewController alloc] init];
        vc.view = content;
        vc;
      })];
  _quickWindow.title = [MacViKeyMenuLayout string:@"quickPanel.title"
                                         fallback:@"MacViKey"];
  _quickWindow.styleMask =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
  _quickWindow.releasedWhenClosed = NO;
  [_quickWindow center];
}

// Dong bo trang thai cac nut voi prefs. Duoc goi tu fillData nen bang nhanh,
// menu va bang dieu khien khong bao gio lech nhau.
- (void)macViKeyRefreshQuickPanel {
  if (_quickWindow == nil)
    return;

  if (_quickStatusButton != nil && mnuStatusLine != nil) {
    _quickStatusButton.title = mnuStatusLine.title;
    _quickStatusButton.toolTip = mnuStatusLine.toolTip;
  }
  for (NSButton *check in _quickOptionButtons) {
    check.state = [self macViKeyOptionIsOn:check.tag] ? NSControlStateValueOn
                                                      : NSControlStateValueOff;
  }
  for (NSButton *radio in _quickSwitchButtons) {
    if (radio.tag < 0 || radio.tag >= (NSInteger)mnuSwitchKeyValues.count)
      continue;
    BOOL on = ((vSwitchKeyStatus | MACVIKEY_SWITCH_BEEP) ==
               [mnuSwitchKeyValues[radio.tag] intValue]);
    radio.state = on ? NSControlStateValueOn : NSControlStateValueOff;
  }
}

- (void)onQuickPanelSelected {
  if (_quickWindow == nil)
    [self macViKeyBuildQuickPanel];
  [self macViKeyRefreshQuickPanel];
  if (_quickWindow.isVisible)
    return;
  [NSApp activateIgnoringOtherApps:YES];
  [_quickWindow makeKeyAndOrderFront:nil];
  [_quickWindow setLevel:NSFloatingWindowLevel];
}

#pragma mark -StatusBar menu data

// Logo cho thanh menu: dung nguyen ban mau (khong phai template) vi hinh co
// nhieu sac do, ep sang don sac se thanh mot vet den. Thu nho ve 18pt cho khop
// chieu cao thanh menu va cache lai - fillData bi goi moi lan doi che do.
- (NSImage *)macViKeyStatusBarLogo {
  static NSImage *logo = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSImage *src = [NSImage imageNamed:@"logo_macvikey"];
    if (src == nil) {
      NSString *path = [[NSBundle mainBundle] pathForResource:@"logo_macvikey"
                                                       ofType:@"png"];
      if (path)
        src = [[NSImage alloc] initWithContentsOfFile:path];
    }
    if (src == nil) {
      NSLog(@"[MacViKey] Khong nap duoc logo_macvikey.png cho thanh menu.");
      return;
    }
    const CGFloat side = 18.0;
    src.size = NSMakeSize(side, side);
    logo = src;
  });
  return logo;
}

- (void)fillData {
  // fill data
  NSInteger intInputMethod =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
  // MacViKey: logo + chu VI / EN. Chi mot trong hai la khong du - logo giup tim
  // ra app giua hang chuc muc tren thanh menu, chu cho biet dang o che do nao.
  statusItem.button.image = [self macViKeyStatusBarLogo];
  statusItem.button.alternateImage = nil;
  statusItem.button.imagePosition = NSImageLeft;
  statusItem.button.imageScaling = NSImageScaleProportionallyDown;
  statusItem.button.font =
      [NSFont monospacedDigitSystemFontOfSize:[NSFont systemFontSize]
                                       weight:NSFontWeightBold];
  statusItem.button.title =
      (intInputMethod == 1)
          ? [MacViKeyMenuLayout string:@"statusBar.vi" fallback:@"VI"]
          : [MacViKeyMenuLayout string:@"statusBar.en" fallback:@"EN"];
  vLanguage = (int)intInputMethod;

  NSInteger intInputType =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"InputType"];
  intInputType = MACVIKEY_FIXED_INPUT_TYPE;
  [mnuTelex setState:NSControlStateValueOff];
  [mnuVNI setState:NSControlStateValueOff];
  [mnuSimpleTelex1 setState:NSControlStateValueOff];
  [mnuSimpleTelex2 setState:NSControlStateValueOff];
  if (intInputType == 0) {
    [mnuTelex setState:NSControlStateValueOn];
  } else if (intInputType == 1) {
    [mnuVNI setState:NSControlStateValueOn];
  } else if (intInputType == 2) {
    [mnuSimpleTelex1 setState:NSControlStateValueOn];
  } else if (intInputType == 3) {
    [mnuSimpleTelex2 setState:NSControlStateValueOn];
  }
  vInputType = (int)intInputType;

  NSInteger intSwitchKeyStatus =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"SwitchKeyStatus"];
  vSwitchKeyStatus = (int)intSwitchKeyStatus;
  if (vSwitchKeyStatus == 0)
    vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
  if (![self macViKeyIsSupportedSwitchKey:vSwitchKeyStatus])
    vSwitchKeyStatus = MACVIKEY_SWITCH_DEFAULT;
  vSwitchKeyStatus |= MACVIKEY_SWITCH_BEEP;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];

  NSInteger intCode =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"CodeTable"];
  intCode = MACVIKEY_FIXED_CODE_TABLE;
  [mnuUnicode setState:NSControlStateValueOff];
  [mnuTCVN setState:NSControlStateValueOff];
  [mnuVNIWindows setState:NSControlStateValueOff];
  [mnuUnicodeComposite setState:NSControlStateValueOff];
  [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOff];
  if (intCode == 0) {
    [mnuUnicode setState:NSControlStateValueOn];
  } else if (intCode == 1) {
    [mnuTCVN setState:NSControlStateValueOn];
  } else if (intCode == 2) {
    [mnuVNIWindows setState:NSControlStateValueOn];
  } else if (intCode == 3) {
    [mnuUnicodeComposite setState:NSControlStateValueOn];
  } else if (intCode == 4) {
    [mnuVietnameseLocaleCP1258 setState:NSControlStateValueOn];
  }
  vCodeTable = (int)intCode;
  [mnuSimpleTelex1 setState:NSControlStateValueOn];
  [mnuUnicode setState:NSControlStateValueOn];

  //
  NSInteger intRunOnStartup =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"RunOnStartup"];
  [self setRunOnStartup:intRunOnStartup ? YES : NO];

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
  [viewController fillData];

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

/// Logo nho dat truoc dong trang thai bo go tren menu.
- (NSImage *)macViKeyMenuLogoImageOfSize:(CGFloat)side {
  NSImage *logo = [NSImage imageNamed:@"logo_macvikey"];
  if (!logo) {
    return nil;
  }
  logo = [logo copy];
  logo.size = NSMakeSize(side, side);
  return logo;
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

- (void)onInputTypeSelected:(id)sender {
  NSMenuItem *menuItem = (NSMenuItem *)sender;
  [self onInputTypeSelectedIndex:(int)menuItem.tag];
}

- (void)onInputTypeSelectedIndex:(int)index {
  index = MACVIKEY_FIXED_INPUT_TYPE;
  [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"InputType"];
  vInputType = index;
  [self fillData];
  [viewController fillData];
}

- (void)onCodeTableChanged:(int)index {
  index = MACVIKEY_FIXED_CODE_TABLE;
  [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CodeTable"];
  vCodeTable = index;
  [self fillData];
  [viewController fillData];
  OnTableCodeChange();
}

- (void)onCodeSelected:(id)sender {
  NSMenuItem *menuItem = (NSMenuItem *)sender;
  [self onCodeTableChanged:(int)menuItem.tag];
}

- (void)onControlPanelSelected {
  if (_mainWC == nil) {
    _mainWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil]
        instantiateControllerWithIdentifier:@"MacViKey"];
  }
  //[MacViKeyManager showDockIcon:YES];
  if ([_mainWC.window isVisible]) {
    return;
  }
  [_mainWC.window makeKeyAndOrderFront:nil];
  [_mainWC.window setLevel:NSFloatingWindowLevel];
}

- (void)onAboutSelected {
  if (_aboutWC == nil) {
    _aboutWC = [[NSStoryboard storyboardWithName:@"Main" bundle:nil]
        instantiateControllerWithIdentifier:@"AboutWindow"];
  }
  //[MacViKeyManager showDockIcon:YES];
  if ([_aboutWC.window isVisible])
    return;

  // Cua so Gioi thieu khong cho resize -> ep kich thuoc dung bang view goc
  // trong storyboard, tranh cat mat noi dung (link, khung ung ho, ban quyen).
  NSView *aboutView = _aboutWC.contentViewController.view;
  if (aboutView) {
    [_aboutWC.window setContentSize:aboutView.frame.size];
    [_aboutWC.window center];
  }

  [_aboutWC.window makeKeyAndOrderFront:nil];
  [_aboutWC.window setLevel:NSFloatingWindowLevel];
}

#pragma mark -Short key event
- (void)onSwitchLanguage {
  [self onInputMethodSelected];
  [viewController fillData];
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
