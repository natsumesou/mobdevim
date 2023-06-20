//
//  springboardservices.m
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2020 Selander. All rights reserved.
//




#import "install_ddi.h"


static void image_callback(NSDictionary *progress, id something) {

//    NSLog(@"%@ %@", something, progress );
//    printf("");
}


int install_ddi(AMDeviceRef d, NSDictionary *options) {

    if (!global_options.ddiInstallPath || !global_options.ddiSignatureInstallPath)
    {
        printf("<DDI> <DDI Signature> needed\n");
        exit(1);
    }
    

    NSData *dataSIG = [NSData dataWithContentsOfFile:global_options.ddiSignatureInstallPath];
    if (!dataSIG)
    {
        printf("Need a valid signature\n");
        exit(1);
    }
    NSDictionary *op = @{@"ImageSignature" :  dataSIG, @"ImageType": @"Developer", @"DiskImage" : @"/Developer"};


     NSError *err = nil;
     mach_error_t  er = AMDeviceMountImage(d,  global_options.ddiInstallPath, op, image_callback, nil, &err);
    
    
    if (err || er != ERR_SUCCESS)
    {
        printf("Error (%s) %s\n", AMDErrorString(er), err.description.UTF8String);
        AMDeviceStopSession(d);
        AMDeviceDisconnect(d);
        return 1;
    }
    

     
    
    return 0;
}
