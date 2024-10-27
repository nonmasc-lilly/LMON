#
#   LMON, A simple 8086 16 bit legacy bios monitor (make.sh)
#   Copyright (C) 2024 Lilly H. St Claire
#            This program is free software: you can redistribute it and/or modify
#            it under the terms of the GNU General Public License as published by
#            the Free Software Foundation, either version 3 of the License, or (at
#            your option) any later version.
#            This program is distributed in the hope that it will be useful, but
#            WITHOUT ANY WARRANTY; without even the implied warranty of
#            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#            General Public License for more details.
#            You should have received a copy of the GNU General Public License
#            along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
TEST=false
for i in $@; do
        if [ $i = "--test" ]; then
                TEST=true
        elif [ $i = "--help" ]; then
                echo "LILMON make script:"
                echo "--help: show help and exit"
                echo "--test: test program after build"
        fi
done

fasm src/mon.asm build/lilmon

if [ "$TEST" = "true" ]; then
        qemu-system-x86_64 -drive file=build/lilmon,format=raw
fi
