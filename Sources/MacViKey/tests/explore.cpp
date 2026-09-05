//  SPDX-License-Identifier: GPL-3.0-or-later
#include <cstdio>
#include "TestHarness.h"
static void P(const char* k){ printf("  %-12s -> %s\n", k, mvk::type(k).c_str()); }
int main(){ vKeyInit();
  printf("\n--- #327 Tu bat dau bang Z/F/W/J, A9 = TAT (mac dinh) ---\n");
  mvk::resetToMacViKeyDefaults();
  P("zoos"); P("faan"); P("jees"); P("zuw");
  printf("\n--- Cung the, A9 = BAT ---\n");
  mvk::resetToMacViKeyDefaults(); vAllowConsonantZFWJ=1; startNewSession();
  P("zoos"); P("faan"); P("jees"); P("zuw");
  printf("\n--- Kiem tra A9 co pha tu binh thuong khong ---\n");
  P("tieengs"); P("dduowcj"); P("nguowif"); P("Vieetj"); P("quownr");
  return 0; }
