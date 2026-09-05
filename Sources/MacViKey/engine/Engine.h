//  SPDX-License-Identifier: GPL-3.0-or-later
//
//  Engine.h
//  MacViKey
//

#ifndef Engine_h
#define Engine_h

#include <locale>
#include <codecvt>

#include "DataType.h"
#include "Vietnamese.h"
#include "SmartSwitchKey.h"

#ifndef LOBYTE
#define LOBYTE(data) (data & 0xFF)
#endif // !LOBYTE
#ifndef HIBYTE
#define HIBYTE(data) ((data>>8) & 0xFF)
#endif // !HIBYTE

#define GET_SWITCH_KEY(data) (data & 0xFF)
#define HAS_CONTROL(data) ((data & 0x100) ? 1 : 0)
#define HAS_OPTION(data) ((data & 0x200) ? 1 : 0)
#define HAS_COMMAND(data) ((data & 0x400) ? 1 : 0)
#define HAS_SHIFT(data) ((data & 0x800) ? 1 : 0)
#define GET_BOOL(data) (data ? 1 : 0)
#define HAS_BEEP(data) (data & 0x8000)

//define these variable in your application
//API
/*
 * 0: English
 * 1: Vietnamese
 */
extern int vLanguage;

/*
 * 0: Telex
 * 1: VNI
 */
extern int vInputType;

/**
 * 0: No
 * 1: Yes
 */
extern int vFreeMark;

/*
 * 0: Unicode
 * 1: TCVN3 (ABC)
 * 2: VNI-Windows
 */
extern int vCodeTable;

/*
 * first 8 bit: keycode
 * bit 8: Control on/off
 * bit 9: Option on/off
 * bit 10: Command on/off
 */
extern int vSwitchKeyStatus;

/**
 * 0: No
 * 1: Yes
 */
extern int vCheckSpelling;

/*
 * 0: òa, úy
 * 1: oà uý
*/
extern int vUseModernOrthography;

/**
 * 0: No
 * 1: Yes
 * (cc=ch, gg=gi, kk=kh, nn=ng, qq=qu, pp=ph, tt=th, uu=ươ)
 */
extern int vQuickTelex;

/**
 * Work together with vCheckSpelling
 * 0: No
 * 1: Yes
 *
 */
extern int vRestoreIfWrongSpelling;

/*
 * Fix recommend browser's address, excel,...
 * 0: No
 * 1: Yes
 */
extern int vFixRecommendBrowser;

/**
 * auto switch language when switch app
 * 0: No
 * 1: Yes
 */
extern int vUseSmartSwitchKey;

/**
 * Auto write upper case character for first letter.
 * 0: No
 * 1: Yes
 */
extern int vUpperCaseFirstChar;

/**
 * Temporarily turn off spell checking with Ctrl key
 * 0: No
 * 1: Yes
 */
extern int vTempOffSpelling;

/**
 * Allow write word with consonant Z, F, W, J
 * 0: No
 * 1: Yes
 */
extern int vAllowConsonantZFWJ;

/**
 * 0: No; 1: Yes
 * f -> ph: fanh -> phanh,...
 * j ->gi: jang -> giang,...
 * w ->qu: wen -> quen,...
 */
extern int vQuickStartConsonant;

/**
 * 0: No; 1: Yes
 * g -> ng: hag -> hang,...
 * h -> nh: vih -> vinh,...
 * k -> ch: bak -> bach,...
 */
extern int vQuickEndConsonant;

/**
 * 0: No; 1: Yes
 * Auto remember table code for each application
 */
extern int vRememberCode;

/**
 * 0: No; 1: Yes
 * Turn off Vietnamese when typing in another language.
 */
extern int vOtherLanguage;

/**
 * 0: No; 1: Yes
 * Temporarily turn off the engine by hot key (Command)
 */
extern int vTempOffEngineByHotKey;

/**
 * Call this function first to receive data pointer
 */
void* vKeyInit();

/**
 * Convert engine character to real character
 */
Uint32 getCharacterCode(const Uint32& data);

/**
 * MAIN entry point for each key
 * event: mouse or keyboard event
 * state: additional state for event
 * data: key code
 * isCaps: caplock is on or shift key is pressing
 * otherControlKey: ctrl, option,... is pressing
 */
void vKeyHandleEvent(const vKeyEvent& event,
                     const vKeyEventState& state,
                     const Uint16& data,
                     const Uint8& capsStatus=0,
                     const bool& otherControlKey=false);

/**
 * Start a new word
 */
void startNewSession();

/**
 * temporarily turn off spell checking
 */
void vTempOffSpellChecking();

/**
 * reset spelling value
 */
void vSetCheckSpelling();

/**
 * temporarily turn off the engine
 */
void vTempOffEngine(const bool& off=true);

/**
 * some utils function
 */
wstring utf8ToWideString(const string& str);
string wideStringToUtf8(const wstring& str);

#endif /* Engine_h */
