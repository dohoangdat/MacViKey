//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  MyTextField.h
//  MacViKey
//

#import <Cocoa/Cocoa.h>

@protocol MyTextFieldDelegate
@optional
-(void)onMyTextFieldKeyChange:(unsigned short)keyCode character:(unsigned short)character;
@end

@interface MyTextField : NSTextField<NSTextDelegate>
@property (weak, nonatomic) id<MyTextFieldDelegate> Parent;
@property unsigned short LastKeyCode;
@property unsigned short LastKeyChar;

-(void)setTextByChar:(unsigned short)chr;
@end
