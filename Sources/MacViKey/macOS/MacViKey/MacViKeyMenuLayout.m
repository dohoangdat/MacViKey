//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyMenuLayout.m
//  MacViKey
//
//  Copyright © 2026 Do Hoang Dat
//

#import "MacViKeyMenuLayout.h"

@implementation MacViKeyMenuLayout

+ (NSDictionary *)layout {
  static NSDictionary *layout = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"MenuLayout"
                                                     ofType:@"json"];
    NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (!data) {
      NSLog(@"[MacViKey] Khong tim thay MenuLayout.json trong app bundle.");
      layout = @{};
      return;
    }
    NSError *error = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&error];
    if (![parsed isKindOfClass:NSDictionary.class]) {
      NSLog(@"[MacViKey] MenuLayout.json hong: %@", error.localizedDescription);
      layout = @{};
      return;
    }
    layout = parsed;
  });
  return layout;
}

+ (NSArray<NSDictionary *> *)nodes {
  id nodes = [self layout][@"menu"];
  return [nodes isKindOfClass:NSArray.class] ? nodes : @[];
}

+ (NSArray<NSDictionary *> *)settingsNodes {
  id nodes = [self layout][@"settings"];
  return [nodes isKindOfClass:NSArray.class] ? nodes : @[];
}

+ (NSString *)string:(NSString *)key fallback:(NSString *)fallback {
  id strings = [self layout][@"strings"];
  if ([strings isKindOfClass:NSDictionary.class]) {
    id value = strings[key];
    if ([value isKindOfClass:NSString.class])
      return value;
  }
  return fallback;
}

@end
