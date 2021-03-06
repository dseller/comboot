# comboot
Boot loader that allows booting kernel using serial (COM) port

[![COMBOOT Boot Loader](https://img.youtube.com/vi/uxUTAgARaJY/0.jpg)](https://www.youtube.com/watch?v=uxUTAgARaJY "COMBOOT Boot Loader")

## Limitations

 * Kernel image multiboot header is not parsed.
 * Multiboot info structure is stubbed right now.
 * Memory detection & memory map are not yet implemented.
 * Stage2 kernel loader jumps to hardcoded 0x100420, which fits my own kernel perfectly.

## Requirements

 * NASM in your PATH variable, the boot sector is assembled using it
 
## Components

 * __bootsect__ is the boot sector that requests the stage2 bootloader
 * __bootsrv__ is the C# host application that implements the BOOTSRV protocol, which serves the files
 * __stage2__ is the stage2 bootloader
 
## How to use

 1. Compile/assemble everything.
 2. Either write the boot sector to a hard disk, or generate an ISO with it.
 3. Connect your 'client system' to your 'host system' using a serial cable.
 4. Configure your bootsrv (in the App.config file) so that it points to the correct COM port and files.
 5. Run bootsrv.exe.
 6. Power on the client system.
 7. If the client is stuck on "hi!", try fiddling with some serial settings.
 
__NOTE__: The boot sector configures the serial port to 9600 bauds, 8 data bits, 1 stop bit, and no flow control.

## Error codes

Note that when the client system shows you a panic message with an error code, that the CPU is halted. In other words,
it is frozen. The only way forward is resetting the system.

 * __01__ means an error in serial communication, such as a timeout
 * __02__ means that an unexpected packet was received
 * __FF__ means that the boot sector ended prematurely
 
 