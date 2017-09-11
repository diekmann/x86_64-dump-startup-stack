# x86_64-dump-startup-stack
When an elf64 binary gets `exec`ed and `_start`ed on Linux, the stack contains useful [information](http://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf). We dump some if it.
