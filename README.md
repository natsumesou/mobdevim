# mobdevim
**Mobile Device Improved**: Command line utility that interacts with plugged in iOS devices. Uses Apple's MobileDevice framework 



## Installation 

1. clone
2. build project
3. Upon build success,` mobdevim` will be placed in **/usr/local/bin**

## Commands

    # Get device information
    mobdevim -f

    # Dump console output, use ctrl-c to stop
    mobdevim -c 
    
    # Get all installed application bundle identifiers
    mobdevim -l
    
    # Get detailed information about the Safari application
    mobdevim -l com.apple.mobilesafari

    # Get detailed information about the Safari application
    mobdevim -y com.apple.mobilesafari
    
    # Get a summary about the provisioning profiles found on the iOS device
    mobdevim -p
    
    # Get detailed information about the provisioning profile whose UUID is "b68410a1-d825-4b8c-8e5d-0f76a9bde6b9"
    mobdevim -p b68410a1-d825-4b8c-8e5d-0f76a9bde6b9
    
    # Copy all the (Developer) certificates from the device back onto computer
    mobdevim -C
    
    # Copy an apps Library/Cache/Document folder to your computer, whose bundle ID is "com.selander.TEST"
    # NOTE: YOU NEED TO HAVE MATCHING CERTIFICATES FOR THE APP OR ELSE THIS WILL FAIL!
    mobdevim -c com.selander.TEST
    
    
More commands will be coming soon...
