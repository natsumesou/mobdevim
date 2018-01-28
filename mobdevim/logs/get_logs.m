//
//  send_files.m
//  mobdevim
//
//  Created by Derek Selander on 12/4/17.
//  Copyright © 2017 Selander. All rights reserved.
//

#import "send_files.h"

NSString * const kGetLogsFilePath = @"com.selander.get_logs.sendfilepath";

NSString * const kGetLogsAppBundle = @"com.selander.get_logs.appbundle";

int get_logs(AMDeviceRef d, NSDictionary *options) {
    
    NSDictionary *dict = nil;
    NSString *appBundle = [options objectForKey:kGetLogsAppBundle];
    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
                            @"ReturnAttributes" : @[@"CFBundleExecutable",
                                                    @"CFBundleIdentifier",
                                                    @"CFBundleDisplayName"]};

    NSString *executableName = nil;
    AMDeviceLookupApplications(d, opts, &dict);
    
    if (appBundle) {
    executableName = [[dict objectForKey:appBundle] objectForKey:@"CFBundleExecutable"];
        if (!executableName) {
            dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [appBundle UTF8String], colorEnd(), dcolor("bold"), colorEnd());
            return 1;
        }
    }
    
    NSString *basePath = [[options objectForKey:kGetLogsFilePath] stringByExpandingTildeInPath];
    if (!basePath) {
        basePath = @"/tmp/";
    }
    
    NSURL *baseURL = [NSURL URLWithString:basePath];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }
    
    baseURL = [baseURL URLByAppendingPathComponent:[NSString stringWithFormat:@"crashes_%@", appBundle]];
    if (!baseURL) {
        dsprintf(stderr, "Couldn't create access path \"%s\", exiting\n", baseURL);
        return 1;
    }

    AMDServiceConnectionRef serviceConnection = nil;
    NSDictionary *inputDict = @{@"CloseOnInvalidate" : @YES, @"InvalidateOnDetach": @YES};
    AMDeviceSecureStartService(d, @"com.apple.crashreportmover", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return EACCES;
    }
    
    void *info = nil;
    if (AMDServiceConnectionReceive(serviceConnection, &info, 5) <= 4) {
        return EACCES;
    }
    if (strcmp("ping", (char *)&info) != 0) {
        dsprintf(stderr, "Didn't get the \"ping\" goahead from com.apple.crashreportmover, got \"%s\" instead, exiting\n", (char *)&info);
        return EACCES;
    }
    AMDServiceConnectionInvalidate(serviceConnection);
    serviceConnection = nil;
    
    // if we got the ping, we're all good, start querying crash logs
    AMDeviceSecureStartService(d, @"com.apple.crashreportcopymobile", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return EACCES;
    }
    long socket = AMDServiceConnectionGetSocket(serviceConnection);
    id context = AMDServiceConnectionGetSecureIOContext(serviceConnection);
    if (context) {
        // TODO Implement this if it's ever valid
        assert(0);
    }
    
    AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
    if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor("yellow"), colorEnd());
        return EACCES;
    }
    
    AFCIteratorRef iteratorRef = NULL;
    AFCDirectoryOpen(connectionRef, ".", &iteratorRef);
    NSError *err = NULL;
    [[NSFileManager defaultManager] createDirectoryAtPath:[baseURL path] withIntermediateDirectories:YES attributes:nil error:&err];
    
    if (err) {
        dsprintf(stdout, "%s. exiting...\n", [[err localizedDescription] UTF8String]);
        return 1;
    }
    
    err = nil;
    char *remotePath = NULL;
    NSMutableDictionary *outputDict = [NSMutableDictionary dictionary];//used for no appBund
    
    while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == 0 && remotePath) {
        
        AFCFileDescriptorRef descriptorRef = NULL;
        if (AFCFileRefOpen(connectionRef, remotePath, 0x1, &descriptorRef) || !descriptorRef) {
            continue;
        }
        
        AFCIteratorRef iteratorRef = NULL;
        if (AFCFileInfoOpen(connectionRef, remotePath, &iteratorRef) && !iteratorRef) {
            dsprintf(stderr, "Couldn't open \"%s\"", remotePath);
            continue;
        }
        
        NSDictionary* fileAttributes = (__bridge NSDictionary *)(iteratorRef->fileAttributes);
        
        // is a directory? ignore
        if ([[fileAttributes objectForKey:@"st_ifmt"] isEqualToString:@"S_IFDIR"]) {
            continue;
        }
        

        if (appBundle && ![[NSString stringWithUTF8String:remotePath] hasPrefix:[NSString stringWithFormat:@"%@.", executableName]]) {
            continue;
        }
        
        
        if (!appBundle) {
            
            NSString *procName = [[[[NSString stringWithUTF8String:remotePath] lastPathComponent] componentsSeparatedByString:@"-20"] firstObject];
            if (![outputDict objectForKey:procName]) {
                [outputDict setObject:@0 forKey:procName];
            }
            
            [outputDict setObject:@([[outputDict objectForKey:procName] integerValue] + 1) forKey:procName];
            AFCFileRefClose(connectionRef, descriptorRef);
            continue;
        }
        
  
        NSURL *finalizedURL = [baseURL URLByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
        [[NSFileManager defaultManager] createFileAtPath:[finalizedURL path] contents:nil attributes:nil];
        
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:finalizedURL error:&err];
        
        if (err) {
            dsprintf(stdout, "%s, exiting...\n", [[err localizedDescription] UTF8String]);
            return 1;
        }
        
        int fd = [handle fileDescriptor];
        if (fd == -1) {
            dsprintf(stderr, "%sCan't open \"%s\" to write to, might be an existing file there.\n", [finalizedURL path]);
            continue;
        }
        
        size_t size = BUFSIZ;
        void *buffer[BUFSIZ];
        while (AFCFileRefRead(connectionRef, descriptorRef, buffer, &size) == 0 && size != 0 && size != -1) {
            write(fd, buffer, size);
        }
        
        [handle closeFile];
        AFCFileRefClose(connectionRef, descriptorRef);
    }
    
    AFCConnectionClose(connectionRef);
    
    if (appBundle) {
        dsprintf(stdout, "Opening \"%s\"...\n", [[baseURL path] UTF8String]);
        if (!quiet_mode) {
            NSString *systemCMDString = [NSString stringWithFormat:@"open -R %@", [baseURL path]];
            system([systemCMDString UTF8String]);
        }
    } else {
        for (NSString *key in outputDict) {
            dsprintf(stdout, "%s issues: %d\n", [key UTF8String], [[outputDict objectForKey:key] integerValue]);
        }
    }

    return 0;
}
