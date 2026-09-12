//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKey-Bridging-Header.h
//  MacViKey — các header Objective-C mà lớp SwiftUI cần thấy
//
//  Chỉ để những header thật sự cần ở đây. Engine (C++) KHÔNG được lọt vào: lớp
//  giao diện không có việc gì với engine, và kéo C++ qua Swift là kéo theo cả
//  một mớ rắc rối không cần thiết.
//
//  Copyright © 2026 Do Hoang Dat
//

#import "MacViKeyInfo.h"
#import "MacViKeyManager.h"
#import "MacViKeyMenuLayout.h"
#import "MacViKeyQuickRow.h"
