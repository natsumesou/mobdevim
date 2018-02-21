//
//  
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#include "helpers.h"



//*****************************************************************************/
#pragma mark - Externals
//*****************************************************************************/

const char *version_string = "0.0.1";
const char *program_name = "mobdevim";
// TODO
// const char *git_hash = "|||||";
const char *usage = "mobdevim [-v] [-l|-l appIdent][-i path_to_app_dir] [-p|-p UUID_PROVSIONPROFILE] [-c] [-C] [-s bundleIdent path] [-f]";
BOOL quiet_mode = NO;




char* dcolor(char *color) {
  static BOOL useColor = NO;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (!useColor) {
    return "";
  }
  if (strcmp("cyan", color) == 0) {
    return "\e[36m";
  } else if (strcmp("yellow", color) == 0) {
    return "\e[33m";
  } else if (strcmp("magenta", color) == 0) {
    return "\e[95m";
  } else if (strcmp("red", color) == 0) {
    return "\e[91m";
  } else if (strcmp("blue", color) == 0) {
    return "\e[34m";
  } else if (strcmp("gray", color) == 0) {
    return "\e[90m";
  } else if (strcmp("bold", color) == 0) {
    return "\e[1m";
  }
  return "";
}

char *colorEnd() {
  static BOOL useColor = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (getenv("DSCOLOR")) {
      useColor = YES;
    }
  });
  if (useColor) {
    return "\e[0m";
  }
  
  return "";
}

void dsprintf(FILE * f, const char *format, ...) {
  if (quiet_mode) {
    return;
  }
  va_list args;
  va_start( args, format );
  vfprintf(f, format, args );
  va_end( args );
}


void print_manpage(void) {
  BOOL hasColor = getenv("DSCOLOR") ? YES : NO;
  if (!hasColor) {
    putenv("DSCOLOR=1");
  }
  char *manDescription = "\n\
  %sName%s\n\
  %s%s%s -- (mobiledevice-improved) Interact with an iOS device (compiled %s)\n\n\
  %sSynopsis%s\n\
  \tmobdevim [-rq][-f]\n\
  \tmobdevim [-rq][-l | -l bundleIdentifier][key]\n\
  \tmobdevim [-rq][-p | -p provisioningUUID]\n\
  \tmobdevim [-rq][-g | -g bundleIdentifier | -g number]\n\
  \tmobdevim [-rq][-i pathToIPA]\n\
  \tmobdevim [-q][-C]\n\
  \tmobdevim [-q][-y bundleIdentifier]\n\
  \tmobdevim [-q][-s bundleIdentifier path]\n\
  \tmobdevim [-c]\n\n\
  %sDescription%s\n\
  \tThe mobdevim utlity interacts with your plugged in iOS device over USB using Apple's private\n\
  framework, MobileDevice.\n\n\
  The options are as follows:\n\
  \t%s-f%s\tGet device info\n\n\
  \t%s-g%s\tGet device logs/issues, use bundleIdentifier or _all, or number for most recent\n\n\
  \t%s-y%s\tYoink sandbox content\n\n\
  \t%s-s%s\tSend content to device (use content from yoink command)\n\n\
  \t%s-i%s\tInstall application, expects path to .ipa file\n\n\
  \t%s-c%s\tDump out the console information. Use ctrl-c to terminate\n\n\
  \t%s-C%s\tGet certificates on device\n\n\
  \t%s-p%s\tDisplay developer provisioning profile info\n\n\
  \t%s-l%s\tDump info about all apps, if a bundleIdentifier is given, it will dump the info for that app.\n\t\tIf a bundleIdentifier and key is given, then it will dump only the info for that key for a bundleIdentifier\n\n\
  \t%s-R%s\tUse color\n\n\
  \t%s-q%s\tQuiet mode, ideal for limiting output or checking if a value exists based upon return status\n\n";
  
  char formattedString[2000];
  snprintf(formattedString, 2000, manDescription, dcolor("bold"), colorEnd(), dcolor("bold"), program_name, colorEnd(), __DATE__, dcolor("bold"), colorEnd(),
           dcolor("bold"), colorEnd(), // -f
           dcolor("bold"), colorEnd(), // -g
           dcolor("bold"), colorEnd(), // -i
           dcolor("bold"), colorEnd(), // -y
           dcolor("bold"), colorEnd(), // -s
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -C
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -p
           dcolor("bold"), colorEnd(), // -l
             dcolor("bold"), colorEnd(), // -l
           dcolor("bold"), colorEnd()); // -q
  
  dsprintf(stdout, "%s", formattedString);
  
  if (!hasColor) {
    unsetenv("DSCOLOR");
  }
}

void assertArg(void) {
  if (!optarg) {
    print_manpage();
    exit(1);
  }
}

NSString * const kOptionArgumentDestinationPath = @"com.selander.destination";


