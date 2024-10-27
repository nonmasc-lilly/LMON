[//]: #
[//]: #   LMON, A simple 8086 16 bit legacy bios monitor (README.md)
[//]: #   Copyright (C) 2024 Lilly H. St Claire
[//]: #            This program is free software: you can redistribute it and/or modify
[//]: #            it under the terms of the GNU General Public License as published by
[//]: #            the Free Software Foundation, either version 3 of the License, or (at
[//]: #            your option) any later version.
[//]: #            This program is distributed in the hope that it will be useful, but
[//]: #            WITHOUT ANY WARRANTY; without even the implied warranty of
[//]: #            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
[//]: #            General Public License for more details.
[//]: #            You should have received a copy of the GNU General Public License
[//]: #            along with this program.  If not, see <https://www.gnu.org/licenses/>.

# LMON
## Lilly H. St Claire

LMON is a simple 8086 monitor, which runs using 16 bit real mode BIOS. Upon booting, it loads
the first 64KB of the boot drive into 0x10000 RAM (save for the first 0x200 bytes, which are
loaded at 0x7C00, this is the monitor code and should be edited at your own risk). 0x10000 to
0x1FFFF is mapped to 0x0000 to 0xFFFF by the monitor. LMON has the following commands:

- `.<x: word>` peeks the byte at address `x` and prints its value
- `,<x: word> <y: byte>` pokes the byte `y` at address `x`
- `$<x: word>` calls the program at `x`
- `%` saves the current state to disk (0x10000 through to 0x1FDFF at 0x0201 to 0xFFFF)

When calling a program, it must be returned using the `retf` assembly instruction when the
stack which the program uses is clear.

It is important to note that spaces in commands are automatically inserted by the monitor, and
should not be typed (typing them will return an error).

To build on linux, use `./make.sh` and `./make.sh --test` respectively. This is simply a wrapper
for: `fasm src/mon.asm build/lilmon` and `qemu-system-x86_64 -drive file=build/lilmon,format=raw`
which should be easily replicateable on windows.

To run on hardware one must acquire a computer which still supports legacy bios mode and load onto
a USB the lilmon binary. On linux one can simply use dd like so:
`dd if=build/lilmon of=/dev/your_drive bs=4M status=progress`. We can then plug into the computer
and boot from the drive.
