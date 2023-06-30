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
        derror("<DDI> <DDI Signature> needed\n");
        exit(1);
    }
    

    NSData *dataSIG = [NSData dataWithContentsOfFile:global_options.ddiSignatureInstallPath];
    if (!dataSIG) {
        printf("Need a valid signature\n");
        exit(1);
    }
    NSDictionary *op = @{@"ImageSignature" :  dataSIG, @"ImageType": @"Developer", @"DiskImage" : @"/Developer"};

     amd_err er = AMDeviceMountImage(d,  global_options.ddiInstallPath, op, image_callback, nil);
    
    
    if ( er != ERR_SUCCESS)
    {
        derror("Error (%s) %d\n", AMDErrorString(er), er);
        return 1;
    } else {
        dprint("Image successfully mounted to /Developer\n");
    }
    AMDeviceStopSession(d);
    AMDeviceDisconnect(d);
    

     
    
    return 0;
}
