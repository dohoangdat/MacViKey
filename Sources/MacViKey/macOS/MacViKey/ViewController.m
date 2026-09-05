//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  ViewController.m
//  MacViKey
//
//  Modifications copyright © 2026 Do Hoang Dat
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "MacViKeyConfig.h"
#import "MacViKeyInfo.h"
#import "MacViKeyManager.h"
#import "MyTextField.h"

extern AppDelegate *appDelegate;
extern void OnSpellCheckingChanged(void);

ViewController *viewController;
extern int vFreeMark;
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vSwitchKeyStatus;
extern int vRestoreIfWrongSpelling;
extern int vFixRecommendBrowser;
extern int vSendKeyStepByStep;
extern int vUseSmartSwitchKey;
extern int vUpperCaseFirstChar;
extern int vTempOffSpelling;
extern int vAllowConsonantZFWJ;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vTempOffEngineByHotKey;
extern int vShowIconOnDock;
extern int vFixChromiumBrowser;
extern int vPerformLayoutCompat;

@implementation ViewController {
  __weak IBOutlet NSButton *CustomSwitchCommand;
  __weak IBOutlet NSButton *CustomSwitchOption;
  __weak IBOutlet NSButton *CustomSwitchControl;
  __weak IBOutlet NSButton *CustomSwitchShift;
  __weak IBOutlet MyTextField *CustomSwitchKey;
  __weak IBOutlet NSButton *CustomBeepSound;
  NSArray *tabviews, *tabbuttons;
  NSRect tabViewRect;
  NSTabViewController *tabController;
}

// MacViKey: phim chuyen gio chon tren menu thanh trang thai (4 to hop co dinh)
// va luon keu beep, nen ca hang o day khong con y nghia.
- (void)macViKeyHideSwitchKeyRow {
  NSMutableArray<NSView *> *controls = [NSMutableArray array];
  for (NSView *v in
       [NSArray arrayWithObjects:CustomSwitchCommand, CustomSwitchOption,
                                 CustomSwitchControl, CustomSwitchShift,
                                 CustomSwitchKey, CustomBeepSound, nil]) {
    [controls addObject:v];
  }
  // Nhan "Phim chuyen:" khong co outlet -> tim theo noi dung trong cung khung
  // chua.
  NSView *container = CustomSwitchShift.superview;
  for (NSView *v in container.subviews) {
    if ([v isKindOfClass:[NSTextField class]] &&
        [((NSTextField *)v).stringValue hasPrefix:@"Phím chuyển"]) {
      [controls addObject:v];
    }
  }
  for (NSView *v in controls) {
    [v setHidden:YES];
    if ([v isKindOfClass:[NSControl class]])
      [(NSControl *)v setEnabled:NO];
  }
}

#pragma mark - MacViKey modern macOS appearance

// MacViKey: dung NSTabViewController chuan cua AppKit thay cho 4 nut push "gia
// lam tab". Loi ich: dieu huong ban phim (Ctrl+Tab), VoiceOver doc dung vai tro
// tab, va he thong tu ve thanh tab theo dung style cua phien ban macOS dang
// chay.
- (void)macViKeyBuildTabViewController {
  // Vung dat tab = hop cua dai nut cu va vung noi dung cua cac box.
  NSRect regionRect = tabViewRect;
  for (NSButton *button in tabbuttons) {
    regionRect = NSUnionRect(regionRect, button.frame);
  }

  tabController = [[NSTabViewController alloc] init];
  tabController.tabStyle = NSTabViewControllerTabStyleSegmentedControlOnTop;
  // Khong dung hieu ung chuyen canh: dung voi thoi quen tab tren macOS va ton
  // trong nguoi dung bat "Reduce motion".
  tabController.transitionOptions = NSViewControllerTransitionNone;

  for (NSInteger i = 0; i < (NSInteger)tabviews.count; i++) {
    NSBox *box = [tabviews objectAtIndex:i];
    NSButton *legacyButton = [tabbuttons objectAtIndex:i];

    NSView *container = [[NSView alloc] initWithFrame:box.bounds];
    container.autoresizesSubviews = YES;

    [box removeFromSuperview];
    [box setHidden:NO];
    box.frame = container.bounds;
    box.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [container addSubview:box];

    NSViewController *pageController = [[NSViewController alloc] init];
    pageController.view = container;
    pageController.title = legacyButton.title;

    NSTabViewItem *item =
        [NSTabViewItem tabViewItemWithViewController:pageController];
    item.label = legacyButton.title;
    [tabController addTabViewItem:item];

    // Nut cu chi con giu title/tag de tuong thich, khong hien thi nua.
    [legacyButton setHidden:YES];
    [legacyButton setEnabled:NO];
  }

  [self addChildViewController:tabController];
  tabController.view.frame = regionRect;
  tabController.view.autoresizingMask =
      ((NSBox *)[tabviews objectAtIndex:0]).autoresizingMask;
  [self.view addSubview:tabController.view];
}

// MacViKey: bo vien/clip-art cu, dung mau he thong de tu dong hop Light/Dark
// Mode.
- (void)macViKeyApplyModernStyle {
  NSMutableArray<NSBox *> *boxes = [NSMutableArray array];
  for (NSView *v in self.view.subviews) {
    if ([v isKindOfClass:[NSBox class]] && v != self.appOK &&
        v != self.permissionWarning) {
      [boxes addObject:(NSBox *)v];
    }
  }
  for (NSBox *box in boxes) {
    box.boxType = NSBoxCustom;
    box.titlePosition = NSNoTitle;
    box.cornerRadius = 10;
    box.borderWidth = 1;
    if (@available(macOS 10.14, *)) {
      box.borderColor = [NSColor separatorColor];
    } else {
      box.borderColor = [NSColor gridColor];
    }
    box.fillColor = [NSColor controlBackgroundColor];
  }

  // Box nam trong tab khong can khung rieng nua: NSTabViewController da ve vung
  // noi dung roi, ve them khung se thanh 2 lop vien long nhau.
  for (NSBox *box in tabviews) {
    box.boxType = NSBoxCustom;
    box.titlePosition = NSNoTitle;
    box.borderWidth = 0;
    box.cornerRadius = 0;
    box.fillColor = [NSColor clearColor];
  }

  [self macViKeyStyleActionButton:[self macViKeyFindButtonWithAction:@selector
                                        (onOK:)]
                             role:0];
  [self macViKeyStyleActionButton:[self macViKeyFindButtonWithAction:@selector
                                        (onDefaultConfig:)]
                             role:1];
  [self macViKeyStyleActionButton:[self macViKeyFindButtonWithAction:@selector
                                        (onTerminateApp:)]
                             role:2];
}

- (NSButton *)macViKeyFindButtonWithAction:(SEL)action {
  for (NSView *v in self.view.subviews) {
    if ([v isKindOfClass:[NSButton class]] &&
        ((NSButton *)v).action == action) {
      return (NSButton *)v;
    }
  }
  return nil;
}

// role: 0 = primary (default), 1 = secondary, 2 = destructive
- (void)macViKeyStyleActionButton:(NSButton *)button role:(NSInteger)role {
  if (button == nil)
    return;

  button.image = nil;
  button.imagePosition = NSNoImage;
  button.bezelStyle = NSBezelStyleRounded;
  button.buttonType = NSButtonTypeMomentaryPushIn;
  button.bordered = YES;
  button.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];

  // Chieu cao 32pt cua bezel "rounded" theo HIG; giu nguyen tam theo chieu doc.
  NSRect frame = button.frame;
  CGFloat centerY = NSMidY(frame);
  frame.size.height = 32;
  frame.size.width = 120;
  frame.origin.y = centerY - frame.size.height / 2;
  button.frame = frame;

  if (role == 0) {
    button.keyEquivalent = @"\r"; // nut mac dinh -> to mau accent cua he thong
    if (@available(macOS 10.14, *)) {
      button.contentTintColor = nil;
    }
  } else if (role == 2) {
    if (@available(macOS 10.14, *)) {
      button.contentTintColor = [NSColor systemRedColor];
    }
  }
  button.toolTip = button.title;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  viewController = self;
  CustomSwitchKey.Parent = self;

  self.appOK.hidden = YES;
  self.permissionWarning.hidden = YES;
  self.retryButton.enabled = NO;

  NSRect parentRect = self.viewParent.frame;
  parentRect.size.height = 490;
  self.viewParent.frame = parentRect;

  // Bang dieu khien chi con tab "Thong tin"; moi tuy chon da chuyen len menu
  // thanh trang thai. Khung noi dung giu nguyen vi tri cu de layout khong lech.
  tabviews = [NSArray arrayWithObjects:self.tabviewInfo, nil];
  tabbuttons = [NSArray arrayWithObjects:self.tabbuttonInfo, nil];
  // Trong storyboard, box noi dung tab cach mep tren cua viewParent 169pt va
  // cao 241pt; autoresizingMask (flexibleMinY) giu nguyen khoang cach do khi
  // viewParent duoc thu ve 490pt ngay ben tren. Tinh lai dung cong thuc ay.
  const CGFloat kTabContentTopInset = 169;
  const CGFloat kTabContentHeight = 241;
  tabViewRect =
      NSMakeRect(20,
                 NSHeight(self.viewParent.frame) - kTabContentTopInset -
                     kTabContentHeight,
                 520, kTabContentHeight);
  self.tabviewInfo.frame = tabViewRect;
  for (NSBox *b in tabviews) {
    b.frame = tabViewRect;
  }
  [self macViKeyBuildTabViewController];

  [self showTab:0];

  // MacViKey: mỗi popup chỉ còn đúng 1 lựa chọn và không cho đổi.
  [_popupInputType removeAllItems];
  [_popupInputType addItemWithTitle:MACVIKEY_INPUT_TYPE_NAME];
  [_popupInputType setEnabled:NO];

  [self.popupCode removeAllItems];
  [self.popupCode addItemWithTitle:MACVIKEY_CODE_TABLE_NAME];
  [self.popupCode setEnabled:NO];

  [self macViKeyHideSwitchKeyRow];

  [self initKey];

  [self fillData];

  // set version info
  self.VersionInfo.stringValue = MacViKeyInfo.versionInfoText;
  [self macViKeyFillContactInfo];

  [self macViKeyApplyModernStyle];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  NSString *version = MacViKeyInfo.versionString;
  self.view.window.title = MacViKeyInfo.appName;
  if (@available(macOS 11.0, *)) {
    // Kieu macOS hien dai: ten app o title, thong tin phu o subtitle.
    self.view.window.subtitle =
        [NSString stringWithFormat:@"Bộ gõ Tiếng Việt — phiên bản %@", version];
  } else {
    self.view.window.title =
        [NSString stringWithFormat:@"%@ %@ — Bộ gõ Tiếng Việt cho macOS",
                                   MacViKeyInfo.appName, version];
  }
}

- (void)viewWillAppear {
  [self initKey];
}

- (void)initKey {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (![MacViKeyManager initEventTap]) {
      // self.permissionWarning.hidden = NO;
      // self.retryButton.enabled = YES;
    } else {
      // self.appOK.hidden = NO;
    }
  });
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  // Update the view, if already loaded.
}

- (void)showTab:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)tabController.tabViewItems.count)
    return;
  if (tabController.selectedTabViewItemIndex != index) {
    tabController.selectedTabViewItemIndex = index;
  }
}

- (IBAction)onTabButton:(NSButton *)sender {
  [self showTab:sender.tag];
}

- (IBAction)onInputTypeChanged:(NSPopUpButton *)sender {
  [appDelegate
      onInputTypeSelectedIndex:(int)[self.popupInputType indexOfSelectedItem]];
}

- (IBAction)onCodeTableChanged:(NSPopUpButton *)sender {
  [appDelegate onCodeTableChanged:(int)[self.popupCode indexOfSelectedItem]];
}

- (IBAction)onLanguageChanged:(id)sender {
  [appDelegate onInputMethodSelected];
}

- (IBAction)onRestart:(id)sender {
  self.appOK.hidden = YES;
  self.permissionWarning.hidden = YES;
  self.retryButton.enabled = NO;

  [self initKey];
}

- (IBAction)onFreeMark:(NSButton *)sender {
  NSInteger val = [self setCustomValue:sender keyToSet:@"FreeMark"];
  vFreeMark = (int)val;
}

- (IBAction)onControlSwitchKey:(NSButton *)sender {
  NSInteger val = [self setCustomValue:sender keyToSet:nil];
  vSwitchKeyStatus &= (~0x100);
  vSwitchKeyStatus |= val << 8;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (IBAction)onOptionSwitchKey:(NSButton *)sender {
  NSInteger val = [self setCustomValue:sender keyToSet:nil];
  vSwitchKeyStatus &= (~0x200);
  vSwitchKeyStatus |= val << 9;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (IBAction)onCommandSwitchKey:(NSButton *)sender {
  NSInteger val = [self setCustomValue:sender keyToSet:nil];
  vSwitchKeyStatus &= (~0x400);
  vSwitchKeyStatus |= val << 10;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (IBAction)onShiftSwitchKey:(NSButton *)sender {
  NSInteger val = [self setCustomValue:sender keyToSet:nil];
  vSwitchKeyStatus &= (~0x800);
  vSwitchKeyStatus |= val << 11;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (void)onMyTextFieldKeyChange:(unsigned short)keyCode
                     character:(unsigned short)character {
  vSwitchKeyStatus &= 0xFFFFFF00;
  vSwitchKeyStatus |= keyCode;
  vSwitchKeyStatus &= 0x00FFFFFF;
  vSwitchKeyStatus |= ((unsigned int)character << 24);
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (IBAction)onBeepSound:(NSButton *)sender {
  unsigned int val = (unsigned int)[self setCustomValue:sender keyToSet:nil];
  vSwitchKeyStatus &= (~0x8000);
  vSwitchKeyStatus |= val << 15;
  [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus
                                             forKey:@"SwitchKeyStatus"];
}

- (NSInteger)setCustomValue:(NSButton *)sender keyToSet:(NSString *)key {
  NSInteger val = 0;
  if (sender.state == NSControlStateValueOn) {
    val = 1;
  } else {
    val = 0;
  }
  if (key != nil)
    [[NSUserDefaults standardUserDefaults] setInteger:val forKey:key];
  return val;
}

- (IBAction)onTerminateApp:(id)sender {
  [NSApp terminate:0];
}

- (void)fillData {
  NSInteger intInputMethod =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"];
  if (intInputMethod == 1) {
    self.VietButton.state = NSControlStateValueOn;
  } else if (intInputMethod == 0) {
    self.EngButton.state = NSControlStateValueOn;
  }

  [self.popupInputType selectItemAtIndex:0];
  [self.popupCode selectItemAtIndex:0];

  // option
  NSInteger freeMark =
      [[NSUserDefaults standardUserDefaults] integerForKey:@"FreeMark"];
  self.FreeMarkButton.state =
      freeMark ? NSControlStateValueOn : NSControlStateValueOff;

  CustomSwitchControl.state = (vSwitchKeyStatus & 0x100)
                                  ? NSControlStateValueOn
                                  : NSControlStateValueOff;
  CustomSwitchOption.state = (vSwitchKeyStatus & 0x200)
                                 ? NSControlStateValueOn
                                 : NSControlStateValueOff;
  CustomSwitchCommand.state = (vSwitchKeyStatus & 0x400)
                                  ? NSControlStateValueOn
                                  : NSControlStateValueOff;
  CustomSwitchShift.state = (vSwitchKeyStatus & 0x800) ? NSControlStateValueOn
                                                       : NSControlStateValueOff;
  CustomBeepSound.state = (vSwitchKeyStatus & 0x8000) ? NSControlStateValueOn
                                                      : NSControlStateValueOff;
  [CustomSwitchKey setTextByChar:((vSwitchKeyStatus >> 24) & 0xFF)];
}

- (IBAction)onOK:(id)sender {
  [self.view.window close];
}

- (IBAction)onDefaultConfig:(id)sender {
  NSAlert *alert = [[NSAlert alloc] init];
  [alert
      setMessageText:@"Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?"];
  [alert addButtonWithTitle:@"Có"];
  [alert addButtonWithTitle:@"Không"];
  [alert beginSheetModalForWindow:self.view.window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == 1000) {
                    [appDelegate loadDefaultConfig];
                    [[NSUserDefaults standardUserDefaults]
                        setInteger:0
                            forKey:@"ShowUIOnStartup"];
                    [[NSUserDefaults standardUserDefaults]
                        setInteger:1
                            forKey:@"RunOnStartup"];
                  }
                }];
}

/// Do moi nhan lien he tu Info.plist (xem MacViKeyInfo) thay vi chuoi trong
/// storyboard, de chi phai sua thong tin o dung mot cho.
- (void)macViKeyFillContactInfo {
  self.HomePageLink.stringValue = MacViKeyInfo.homePageURL.absoluteString ?: @"";
  self.IssuesLink.stringValue = MacViKeyInfo.issuesURL.absoluteString ?: @"";
  self.EmailLink.stringValue = MacViKeyInfo.authorEmail;
  self.CopyrightInfo.stringValue = MacViKeyInfo.copyrightShort;
  self.AboutText.stringValue = MacViKeyInfo.aboutText;
}

- (IBAction)onHomePageLink:(id)sender {
  [MacViKeyInfo openURL:MacViKeyInfo.homePageURL];
}

- (IBAction)onFanpageLink:(id)sender {
  [MacViKeyInfo openURL:MacViKeyInfo.issuesURL];
}

- (IBAction)onEmailLink:(id)sender {
  [MacViKeyInfo openURL:MacViKeyInfo.authorMailtoURL];
}

- (IBAction)onSourceCode:(id)sender {
  [MacViKeyInfo openURL:MacViKeyInfo.sourceCodeURL];
}

@end
