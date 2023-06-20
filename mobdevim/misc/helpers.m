//
//  
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "helpers.h"


//*****************************************************************************/
#pragma mark - Externals
//*****************************************************************************/

const char *version_string = "0.0.1";
const char *program_name = "mobdevim";

const char *usage = "mobdevim [-v] [-l|-l appIdent][-i path_to_app_dir] [-p|-p UUID_PROVSIONPROFILE] [-c] [-C] [-s bundleIdent path] [-f]";

char* dcolor(const char *color) {
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

void dprint(const char *format, ...) {
    va_list args;
    va_start( args, format );
    vfprintf(stdout, format, args );
    va_end( args );
}

void dsprintf(FILE * f, const char *format, ...) {
  if (global_options.quiet) {
    return;
  }
  va_list args;
  va_start( args, format );
  vfprintf(f, format, args );
  va_end( args );
}


void dsdebug(const char *format, ...) {
    if (global_options.quiet) { return; }
    
    static dispatch_once_t onceToken;
    static BOOL debugFlag = 0;
    dispatch_once(&onceToken, ^{
        if (getenv("DSDEBUG")) {
            debugFlag = YES;
        } else {
            debugFlag = NO;
        }
    });
    
    if (debugFlag) {
        va_list args;
        va_start( args, format);
        vfprintf(stdout, format, args );
        va_end( args );
    }
    
}

void String4Interface(InterfaceType interface, char **out_str) {
    InterfaceType type = global_options.deviceSelection.type;
    
    switch (type) {
        case InterfaceTypeYOLODontCare:
            *out_str = "Any";
            break;
        case InterfaceTypeUSB:
            *out_str = "USB";
            break;
        case InterfaceTypeWIFI:
            *out_str = "WIFI";
        default:
            *out_str = NULL;
            break;
    }

}

void ErrorMessageThenDie(const char *message, ...) {
    if (!global_options.quiet) {
        va_list args;
        va_start(args, message);
        vfprintf(stderr, message, args);
        va_end( args );
    }
    exit(1);
}


void print_manpage(void) {
  BOOL hasColor = getenv("DSCOLOR") ? YES : NO;
  if (!hasColor) {
    putenv("DSCOLOR=1");
  }
  char *manDescription = "\n\
  %sName%s\n\
  %s%s%s -- (mobiledevice-improved) Interact with a plugged in iOS device (compiled %s)\n\n\
  %sDescription%s\n\
  \tThe mobdevim utlity interacts with your plugged in iOS device over USB using Apple's\n\
  \tframework, MobileDevice.\n\n\
  The options are as follows:\n\
  \t%s-f%s\tGet device info\n\n\
  \t%s-F%s\tList or connect to specific device\n\
          \t\t%smobdevim -F%s List all known devices\n\
          \t\t%smobdevim -F 00234%s Connect to first device that has a UDID of 00234\n\n\
  \t%s-d%s\tDebug application\n\
          \t\t%smobdevim -d /application/bundle/on/mac/%s Debugs application (must install app first)\n\n\
    \t%s-D%s\tQuick Debug application\n\
            \t\t%smobdevim -D /application/bundle/on/mac/%s Quick Debugs application (must install app first)\n\n\
  \t%s-g%s\tGet device logs/issues\n\
          \t\t%smobdevim -g com.example.name%s Get issues for com.example.name app\n\
          \t\t%smobdevim -g 3%s Get the 3rd most recent issue\n\
          \t\t%smobdevim -g __all%s Get all the logs\n\n\
      \t%s-r%s\tRemove file\n\
              \t\t%smobdevim -r /fullpath/to/file%s removes file (sandbox permitting)%s\n\n\
  \t%s-y%s\tYoink sandbox content\n\
          \t\t%smobdevim -y com.example.test%s Yoink contacts from app\n\n\
  \t%s-s%s\tSend content to device (use content from yoink command)\n\
          \t\t%smobdevim -s com.example.test /tmp/com.example.test%s Send contents in /tmp/com.example.test to app\n\n\
  \t%s-i%s\tInstall application, expects path to bundle\n\
          \t\t%smobdevim -i /path/to/app/bundle%s Install app\n\n\
    \t%s-w%s\tConnect device to WiFi mode\n\
            \t\t%smobdevim -w%s Connect device to wifi for this computer\n\
            \t\t%smobdevim -w uuid_here%s Connect device to wifi for UUID\n\
            \t\t%smobdevim -w ?%s Display the computer's host uuid\n\n\
  \t%s-S%s\tArrange SpringBoard icons\n\
          \t\t%smobdevim -S%s Get current SpringBoard icon layout\n\
          \t\t%smobdevim -S /path/to/plist%s Set SpringBoard icon layout from plist file\n\
          \t\t%smobdevim -S asshole%s Set SpringBoard icon layout to asshole mode\n\
          \t\t%smobdevim -S restore%s Restore SpringBoard icon layout (if backup was created)\n\n\
  \t%s-u%s\tUninstall application, expects bundleIdentifier\n\
          \t\t%smobdevim -u com.example.test%s Uninstall app\n\n\
  \t%s-c%s\tDump out the console information. Use ctrl-c to terminate\n\n\
  \t%s-C%s\tGet developer certificates on device\n\n\
  \t%s-p%s\tDisplay running processes on the device\n\n\
  \t%s-P%s\tDisplay developer provisioning profile info\n\
            \t\t%smobdevim -P%s List all installed provisioning profiles\n\
            \t\t%smobdevim -_ b68410a1-d825-4b7c-8e5d-0f76a9bde6b9%s Get detailed provisioning UUID info\n\n\
  \t%s-l%s\tList app information\n\
        \t\t%smobdevim -l%s List all apps\n\
        \t\t%smobdevim -l com.example.test%s Get detailed information about app, com.example.test\n\
        \t\t%smobdevim -l com.example.test Entitlements%s List \"Entitlements\" key from com.example.test\n\n\
  \t%s-L%s\tSimulate location\n\
        \t\t%smobdevim -L 0 0%s Remove location simulation\n\
        \t\t%smobdevim -L 40.7128 -73.935242%s Simulate phone in New York\n\n\
    \t%s-o%s\tOpen application\n\
          \t\t%smobdevim -o com.reverse.domain%s open app\n\
          \t\t%smobdevim -o com.reverse.domain -A \"Some args here\" -V AnEnv=EnValue -V A=B%s open app with launch args and env vars\n\n\n\
  \t%s-R%s\tUse color\n\n\
  \t%s-q%s\tQuiet mode, ideal for limiting output or checking if a value exists based upon return status\n\n\n\
  Environment variables:\n\t%sDSCOLOR%s - Use color (same as -R)\n\n\
  \t%sDSDEBUG%s - verbose debugging\n\n\
  \t%sDSPLIST%s - Display output in plist form (mobdevim -l com.test.example)\n\n\
  \t%sOS_ACTIVITY_DT_MODE%s - Combine w/ DSDEBUG to enable MobileDevice logging\n";
  
  char formattedString[4096];
  snprintf(formattedString, 4096, manDescription, dcolor("bold"), colorEnd(), dcolor("bold"), program_name, colorEnd(), __DATE__, dcolor("bold"), colorEnd(),
           dcolor("bold"), colorEnd(), // -f
           dcolor("bold"), colorEnd(), // -F
           dcolor("bold"), colorEnd(), // -F
           dcolor("bold"), colorEnd(), // -F
           dcolor("bold"), colorEnd(), // -d
           dcolor("bold"), colorEnd(), // -d
           dcolor("bold"), colorEnd(), // -D
           dcolor("bold"), colorEnd(), // -D
           dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
               dcolor("bold"), colorEnd(), // -g
           dcolor("bold"), colorEnd(), // -i
               dcolor("bold"), colorEnd(), // -i
           dcolor("bold"), colorEnd(), // -u
               dcolor("bold"), colorEnd(), // -u
           dcolor("bold"), colorEnd(), // -D
           dcolor("bold"), colorEnd(), // -y
               dcolor("bold"), colorEnd(), // -y
           dcolor("bold"), colorEnd(), // -s
               dcolor("bold"), colorEnd(), // -g
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -C
           dcolor("bold"), colorEnd(), // -c
           dcolor("bold"), colorEnd(), // -p
           dcolor("bold"), colorEnd(), // -p
               dcolor("bold"), colorEnd(), // -p
               dcolor("bold"), colorEnd(), // -p
           dcolor("bold"), colorEnd(), // -l
           dcolor("bold"), colorEnd(),
           dcolor("bold"), colorEnd(), // -r
       dcolor("bold"), colorEnd(),// -r
               dcolor("bold"), colorEnd(), // -w
               dcolor("bold"), colorEnd(), // -w
               dcolor("bold"), colorEnd(), // -w
           dcolor("bold"), colorEnd(), // -S
               dcolor("bold"), colorEnd(), // -S
               dcolor("bold"), colorEnd(), // -S
               dcolor("bold"), colorEnd(), // -S
               dcolor("bold"), colorEnd(), // -S
               dcolor("bold"), colorEnd(), // -l
               dcolor("bold"), colorEnd(), // -l
               dcolor("bold"), colorEnd(), // -l
           dcolor("bold"), colorEnd(), // -L
             dcolor("bold"), colorEnd(), // -L
             dcolor("bold"), colorEnd(), // -L
           dcolor("bold"), colorEnd(), // -o
             dcolor("bold"), colorEnd(), // -o
             dcolor("bold"), colorEnd(), // -o
           dcolor("bold"), colorEnd(), // -R
           dcolor("bold"), colorEnd(), // -R
           dcolor("bold"), colorEnd(), // -R
           dcolor("bold"), colorEnd(), // -q
           dcolor("bold"), colorEnd()); // -OS_ACTIVITY_DT_MODE
  
  dsprintf(stdout, "%s", formattedString);
  
  if (!hasColor) {
    unsetenv("DSCOLOR");
  }
}

__attribute__((visibility("hidden")))
void assert_opt_arg(void) {
  if (!optarg) {
    print_manpage();
    exit(5);
  }
}

NSString *GetHostUUID() {
    CFUUIDBytes hostuuid;
    const struct timespec tmspec = { 0 };
    gethostuuid(&hostuuid.byte0, &tmspec);
    CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, hostuuid);
    return  CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, ref));
}

BOOL isWIFIConnected(AMDeviceRef d, NSString *uuid) {
    NSNumber *isWifiDebugged = AMDeviceCopyValue(d, @"com.apple.mobile.wireless_lockdown", @"EnableWifiDebugging", 0);
    id wirelessHosts = AMDeviceCopyValue(d, @"com.apple.xcode.developerdomain", @"WirelessHosts", 0);
    if (![isWifiDebugged boolValue]) {
        return NO;
    }
    
    if ([wirelessHosts containsObject:uuid]) {
        return YES;
    }
        
    return NO;
}

/// Options used for getopt_long
option_params global_options = {};

NSString * const kOptionArgumentDestinationPath = @"com.selander.destination";


char* InterfaceTypeString(InterfaceType type) {
    switch (type) {
        case InterfaceTypeYOLODontCare:
            return "Unknown";
        case InterfaceTypeUSB:
            return "USB";
        case InterfaceTypeWIFI:
            return "WIFI";
        default:
            break;
    }
}

