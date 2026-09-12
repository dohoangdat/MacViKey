//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyMenuLayout.h
//  MacViKey — doc thu tu + chu cua menu tu Resources/MenuLayout.json
//
//  Copyright © 2026 Do Hoang Dat
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Truy cap file mo ta menu (thu tu, chu, menu con). Doc mot lan roi nho lai.
@interface MacViKeyMenuLayout : NSObject

/// Cay menu tha xuong tren thanh trang thai.
+ (NSArray<NSDictionary *> *)nodes;

/// Cay cua so Cai dat: mang cac trang, moi trang co 'items' rieng.
+ (NSArray<NSDictionary *> *)settingsNodes;

/// Cau chu co phan thay doi luc chay. Thieu key thi tra ve `fallback`.
+ (NSString *)string:(NSString *)key fallback:(NSString *)fallback;

@end

NS_ASSUME_NONNULL_END
