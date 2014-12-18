Nimbus
======

Nimbus is a nim eval IRC bot, primarily for #nim. The eval code here is based off the original eval code in my toy bot BillsPC. Nimbus works by building a local copy of the Portable C Compiler (since a faster compilation time is more important in this case than a better designed ELF) and a local copy of the nim compiler. Nimbus runs in the MOE Competition Sandbox (thank you @charliesome) because it has certain features such as preventing syscalls and has a timeout function
