# VDC_display_latch_test

This is a test rom to check when the VDC latches the value from CR reg for Background and Sprites.

Info:
----

 When the display starts, and BG and Sprites are both disabled, the entire frame is disabled from showing video,
 and "burst mode" is enabled. The point of this demo is to see when the CR values are read and burst mode is
 determined.
