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
const char *usage = "mobdevim [-v] [-l] [-L appbundleID] [-i path_to_app_dir] [-p -c] [-c -P UUID]";
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
  \tmobdevim [-rq][-l | -l bundleIdentifier]\n\
  \tmobdevim [-rq][-p | -p provisioningUUID]\n\
  \tmobdevim [-rq][-f]\n\
  \tmobdevim [-q ][-C]\n\
  \tmobdevim [-c]\n\n\
  %sDescription%s\n\
  \tThe mobdevim utlity interacts with your plugged in iOS device over USB using Apple's private\n\
  framework, MobileDevice. The functionality in this utility has been reverse engineered out the\n\
  functionality of MobileDevice\n\
  \n\
  The options are as follows:\n\
  \t%s-f%s\tGet information about the device\n\n\
  \t%s-c%s\tDump out the console information. Use ctrl-c to terminate\n\n";
  
  char formattedString[2000];
  snprintf(formattedString, 2000, manDescription, dcolor("bold"), colorEnd(), dcolor("bold"), program_name, colorEnd(), __DATE__, dcolor("bold"), colorEnd(), dcolor("bold"), colorEnd(), dcolor("bold"), colorEnd(), dcolor("bold"), colorEnd());
  
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


