# ADIT 600

Connect to serial port at 9600bps
Press enter
> restore defaults
reset
y
Press enter
set local off
set a:1 down
set a:2 down
disconnect a
y
set a:1:1-8 type voice
set a:1:1-8 signal gs
set 1:1-8 signal gs
connect a:1:1-8 1:1-8
set clock1 internal
set a:1 up