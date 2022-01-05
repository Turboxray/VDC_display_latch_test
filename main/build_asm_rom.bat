echo off
del log.txt



pceas -raw main.asm -l 3 -S > log.txt
type log.txt
del Display_off_test.pce
ren main.pce disp_off_test.pce
pause
