# mobdevim
**Mobile Device Improved**: Command line utility that interacts with plugged in iOS devices. Uses Apple's MobileDevice framework 

---

<a href="https://store.raywenderlich.com/products/advanced-apple-debugging-and-reverse-engineering" target="_blank"><img align="right"  height="90"  src="https://github.com/DerekSelander/LLDB/blob/master/Media/dbgbook.png"></a>

This information was extracted out using the help of <a href="https://github.com/DerekSelander/LLDB" target="_blank">**these LLDB scripts  found here**</a>. If you want to learn how to create these scripts or have a better understanding how one can reverse engineer a compiled binary, check out <a href="https://store.raywenderlich.com/products/advanced-apple-debugging-and-reverse-engineering" target="_blank">**Advanced Apple Debugging and Reverse Engineering**</a>

---

## Installation 

1. clone
2. build project
3. Upon build success,` mobdevim` will be placed in **/usr/local/bin**

---

Alternatively, a precompiled version is available <a href="https://github.com/DerekSelander/mobdevim/raw/master/compiled" target="_blank">here</a>.

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
    # NOTE: YOU NEED TO HAVE MATCHING CERTIFICATES FOR THE APP OR ELSE THIS WILL FAIL!
    mobdevim -y com.selander.TEST
    
    # Get a summary about the provisioning profiles found on the iOS device
    mobdevim -p
    
    # Get detailed information about the provisioning profile whose UUID is "b68410a1-d825-4b8c-8e5d-0f76a9bde6b9"
    mobdevim -p b68410a1-d825-4b8c-8e5d-0f76a9bde6b9
    
    # Copy all the (Developer) certificates from the device back onto computer
    mobdevim -C
  
    
    
More commands will be coming soon...
