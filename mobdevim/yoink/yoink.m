//
//  yoink.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//

#import "yoink.h"
#include <time.h>
#include <utime.h>
#include <sys/stat.h>

NSString * const kYoinkBundleIDContents = @"com.selander.yoink.bundleid";

/// Max file size found in AFCFileRefRead
#define MAX_TRANSFER_FILE_SIZE 8191

int yoink_app(AMDeviceRef d, NSDictionary *options) {
    NSDictionary *dict;
    int returnError = 0;
    NSString *appBundle = [options objectForKey:kYoinkBundleIDContents];
    NSDictionary *opts = @{ @"ApplicationType" : @"Any",
                            @"ReturnAttributes" : @[@"ApplicationDSID",
                                                    @"ApplicationType",
                                                    @"CFBundleDisplayName",
                                                    @"CFBundleExecutable",
                                                    @"CFBundleIdentifier",
                                                    @"CFBundleName",
                                                    @"CFBundleShortVersionString",
                                                    @"CFBundleVersion",
                                                    @"Container",
                                                    @"Entitlements",
                                                    @"EnvironmentVariables",
                                                    @"MinimumOSVersion",
                                                    @"Path",
                                                    @"ProfileValidated",
                                                    @"SBAppTags",
                                                    @"SignerIdentity",
                                                    @"UIDeviceFamily",
                                                    @"UIRequiredDeviceCapabilities"]};
    
    AMDeviceLookupApplications(d, opts, &dict);
    NSString *appPath = [[dict objectForKey:appBundle] objectForKey:@"Path"];
    
    if (!appPath) {
        dsprintf(stderr, "%sCouldn't find the bundleIdentifier \"%s\", try listing all bundleIDs with %s%smobdevim -l%s\n", dcolor("yellow"), [appBundle UTF8String], colorEnd(), dcolor("bold"), colorEnd());
        return 1;
    }
    
    dsprintf(stdout, "Searching through directory contents for \"%s\"...\n", [appBundle UTF8String]);
    
    AMDServiceConnectionRef serviceConnection = nil;
    NSDictionary *inputDict = @{@"CloseOnInvalidate" : @NO, @"UnlockEscrowBag": @YES};
    AMDeviceSecureStartService(d, @"com.apple.mobile.house_arrest", inputDict, &serviceConnection);
    if (!serviceConnection) {
        return 1;
    }
    
    
    NSDictionary *inputDictionary = @{ @"Command" : @"VendContainer", @"Identifier" : appBundle };
    if (AMDServiceConnectionSendMessage(serviceConnection, inputDictionary, kCFPropertyListXMLFormat_v1_0)) {
        return 1;
    }
    
    __unused NSString *outputDirectory = [options objectForKey:kOptionArgumentDestinationPath] ? [options objectForKey:kOptionArgumentDestinationPath] : [NSString stringWithFormat:@"/tmp/%@_app", appBundle];
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    long socket = AMDServiceConnectionGetSocket(serviceConnection);
    
    id info = nil;
    AMDServiceConnectionReceiveMessage(serviceConnection, &info, nil);
    
    
    NSString *currentDirectory = @"/";
    
    NSMutableSet *unexploredDirectories = [NSMutableSet set];
    NSMutableSet *exploredDirectories = [NSMutableSet set];
    NSMutableSet *exploredFiles = [NSMutableSet set];
    NSMutableSet *unexploredFiles = [NSMutableSet set];
    
    NSMutableDictionary *filePermissions = [NSMutableDictionary dictionary];
    
    [unexploredDirectories addObject:currentDirectory];
    
    AFCConnectionRef connectionRef = AFCConnectionCreate(0, (int)socket, 1, 0, 0);
    if (!connectionRef) {
        dsprintf(stderr, "%sCould not obtain a valid connection. Aborting%s\n", dcolor("yellow"), colorEnd());
        return 1;
    }
    
    BOOL successfullyReadADirectory = NO;
    while ([unexploredDirectories count] > 0) {
        
        char* remotePath = nil;
        AFCIteratorRef iteratorRef = nil;
        
        AFCDirectoryOpen(connectionRef, [currentDirectory UTF8String], &iteratorRef);
        
        while (AFCDirectoryRead(connectionRef, iteratorRef, &remotePath) == 0 && remotePath) {
            
            successfullyReadADirectory = YES;
            if (strcmp(remotePath, ".") == 0 || strcmp(remotePath, "..") == 0) {
                continue;
            }
            
            AFCIteratorRef fileIterator = NULL;
            NSString *pathReference = [currentDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
            AFCFileInfoOpen(connectionRef, [pathReference UTF8String], &fileIterator);
            
            if (!fileIterator) {
                [exploredFiles addObject:pathReference];
                continue;
            }
            
            NSDictionary *filePermissionOptions = [(__bridge NSDictionary *)(fileIterator->fileAttributes) copy];
            NSString *file = [currentDirectory stringByAppendingPathComponent:[NSString stringWithUTF8String:remotePath]];
            
            if ([filePermissionOptions[@"st_ifmt"] isEqualToString:@"S_IFDIR"]) {
                [unexploredDirectories addObject:file];
                [exploredDirectories addObject:file];
            } else {
                [unexploredFiles addObject:file];
                [exploredFiles addObject:file];
            }
            
            NSString *finalizedFile = [outputDirectory stringByAppendingString:file];
            [filePermissions setObject:filePermissionOptions forKey:finalizedFile];
        }
        
        [unexploredDirectories removeObject:currentDirectory];
        NSString *nextDirectory = [unexploredDirectories anyObject];
        currentDirectory = nextDirectory;
        AFCDirectoryClose(connectionRef, iteratorRef);
    }
    
    NSFileManager *manager = [NSFileManager defaultManager];

    // write the directories first
    for (NSString *path in exploredDirectories) {
        NSString *finalizedDirectory = [outputDirectory stringByAppendingPathComponent:path];
        [manager createDirectoryAtPath:finalizedDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // write the files
    NSArray *paths = [exploredFiles allObjects];
    for (NSString *path in paths) {
        NSString *finalizedFile = [outputDirectory stringByAppendingPathComponent:path];


        AFCFileDescriptorRef ref = NULL;
        if (AFCFileRefOpen(connectionRef, [path UTF8String], 0x1, &ref) || !ref) {
            continue;
        }
        
//        [[NSFileManager defaultManager] createDirectoryAtPath:finalizedFile withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSError *err = NULL;
        [[NSFileManager defaultManager] createFileAtPath:finalizedFile contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:[NSURL URLWithString:finalizedFile] error:&err];
        if (err) {
            dsprintf(stdout, "%s\nExiting...\n", [[err localizedDescription] UTF8String]);
            return 1;
        }
        int fd = [handle fileDescriptor];
        
        if (fd == -1) {
            dsprintf(stderr, "%sCan't open \"%s\" to write to, might be an existing file there.\n", dcolor("yellow"), [finalizedFile UTF8String], colorEnd());
            returnError = 1;
            continue;
            //      return 1;
        }
        
        size_t size = BUFSIZ;
        void *buffer[BUFSIZ];
//        void *buffer[52428800];
        
//        buffer = malloc(size);
        while (AFCFileRefRead(connectionRef, ref, buffer, &size) == 0 && size != 0 && size != -1) {
            write(fd, buffer, size);
        }
        
        [handle closeFile];
        AFCFileRefClose(connectionRef, ref);
    }
    
    AFCConnectionClose(connectionRef);
    
    for (NSString *file in filePermissions) {
        NSDictionary *permissions = filePermissions[file];
        struct stat filestat;
        if (stat([file UTF8String], &filestat) != 0) { continue; }
        
        
        
        for (NSString *permission in permissions) {
            
            if ([permission isEqualToString:@"st_birthtime"]) {
                //        filestat.st_birthtimespec = time(<#time_t *#>);
                
            } else if ([permission isEqualToString:@"st_mtime"]) {
                
            }
        }
    }
    
    if (successfullyReadADirectory) {
        dsprintf(stdout, "Opening \"%s\"...\n", [outputDirectory UTF8String]);
        if (!quiet_mode) {
            NSString *systemCMDString = [NSString stringWithFormat:@"open -R %@", outputDirectory];
            system([systemCMDString UTF8String]);
        }
    } else {
        dsprintf(stderr, "%sUnable to open \"%s\", likely due to not having certificates that match on this device%s\n", dcolor("yellow"), [appBundle UTF8String], colorEnd());
        returnError = 1;
    }
    
    return returnError;
}


