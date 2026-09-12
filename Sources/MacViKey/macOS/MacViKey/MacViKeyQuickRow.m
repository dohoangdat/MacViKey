//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MacViKeyQuickRow.m
//  MacViKey
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

#import "MacViKeyQuickRow.h"

@implementation MacViKeyQuickRow

+ (instancetype)rowWithKind:(MacViKeyQuickRowKind)kind
                      rowId:(NSString *)rowId
                      title:(NSString *)title {
  MacViKeyQuickRow *row = [[self alloc] init];
  row.kind = kind;
  row.rowId = rowId ?: @"";
  row.title = title ?: @"";
  row.children = @[];
  return row;
}

@end
