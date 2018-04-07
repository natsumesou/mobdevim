//
//  colors.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSArray+Output.h"

/// Version String
extern const char *version_string;

/// Program Name
extern const char *program_name;

/// Usage of program
extern const char *usage;


/**
 Uses color of the DSCOLOR env var is set or -r option is used
 Possible options are:
 
 cyan
 yellow
 magenta
 red
 blue
 gray
 bold
 
 You must use the *colorEnd* function to stop using that color
 */
char* dcolor(char *color);

/// Ends the color option if the DSCOLOR env var is set
char *colorEnd(void);

/// My printf
void dsprintf(FILE * f, const char *format, ...);

/// Enabled by DSDEBUG env var
void dsdebug(const char *format, ...);

/// Message then die
void ErrorMessageThenDie(const char *message, ...);

/// If true this will disable stderr/stdout
extern BOOL quiet_mode;

/// Self explanatory, right?... right?
void print_manpage(void);

/// Makes sure the optarg is valid, exit(1) if false
void assertArg(void);


///
extern NSString * const kOptionArgumentDestinationPath;
