//
//  Console.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//

#import "console.h"
//#import <stdio.h>
#import <sys/socket.h>

#define SIZE 2
NSString *const kConsoleProcessName = @"com.selander.console.processname";

int console(AMDeviceRef d, NSDictionary* options) {
    
    AMDServiceConnectionRef connection = NULL;
    AMDeviceSecureStartService(d, @"com.apple.syslog_relay",
                               @{@"UnlockEscrowBag" : @YES},
                               &connection);
    AMDeviceStopSession(d);
    
    char buffer[SIZE];
    memset(buffer, '\0', SIZE);
    
    int amountRead = 0;
    setbuf(stdout, NULL);
    while (1) {
        amountRead = (int)AMDServiceConnectionReceive(connection, buffer, SIZE - 1 ); // Get those "P-\x01" bytes then end, easiest way to fix
        dsprintf(stdout, "%s", buffer);
        memset(buffer, '\0', SIZE);
    }

    return 0;
}
