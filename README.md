# Milestone 1: canvas, pen, VGA display (Emily) + mouse input and toolbar (Imalya)

AI-ASSISTED: the Verilog and testbenches in this folder were written with
Claude (Anthropic). The TA confirmed AI use is allowed for this project.
Check that the course policy and any required citations are met before submitting.

## Files
- rtl/canvas_ram.v: 160x120 framebuffer, 3-bit colour, one write port, one read port
- rtl/pen_engine.v: writes the colour at the cursor while the button is held (one pixel per clock)
- rtl/display_fsm.v: scans the canvas in raster order and sends (x, y, colour, plot) to the VGA adapter
- rtl/top_m1.v: board demo top level (KEY/SW controls, course vga_adapter)
- rtl/mouse_packet_parser.v: PS/2 3-byte packet parser (buttons, signed dx/dy, resync on byte 0 bit 3)
- rtl/mouse_tracker.v: cursor position from dx/dy, Y inverted, clamped to 0..159 / 0..119 (no wrap)
- rtl/mouse_init.v: waits for the mouse's 0xFA ack, then lets bytes through to the parser
  (the course PS2_Controller sends 0xF4 itself when INITIALIZE_MOUSE = 1)
- rtl/top_m2.v: mouse board demo (mouse cursor, left button draws, palette in the bottom 8 rows, cursor overlay)
- ps2/: course PS2_Controller (starter code, unchanged, cite it)
- rtl/toolbar.v: palette hit-testing (rows 112..119, 8 swatches of 20 px)
- sim/tb_*.v: ModelSim/Icarus testbenches (do NOT add to Quartus)

## Simulation results (Icarus Verilog, all PASS)
- tb_canvas_ram: writes 4 pixels (first, last and two others), reads them back, untouched pixel = 0
- tb_pen_engine: 11 pen writes along row 10 from x=10 to x=20, no writes with the button up
- tb_display: all 19,200 pixels visited once in raster order, with the expected colour
- tb_packet_parser: +/- movement, left/right buttons, resync after garbage bytes, one pulse per packet
- tb_tracker: reset to (80,60), movement, clamping at all four edges, no wrap, button
- tb_toolbar: clicks outside the palette ignored, all 8 swatches, held button fires once
- tb_mouse_init: ignores 0xAA/0x00, done on 0xFA, reset clears it
- tb_mouse_system: bytes -> init -> parser -> tracker -> toolbar: packets before the ack ignored,
  movement /2, edge clamping, palette click selects a colour
- top_m2 elaborates with the real course PS/2 core (Icarus needed a copy with `reg init_done` moved
  above its first use; Quartus accepts the course file as is)

## Board build
- Course VGA files are in course_vga/ (copy them into the Quartus project with the rtl/ files).
- rtl/black_160x120.mif is the blank 160x120 background. The course rainbow file is 640x480, so don't use it here.
- top_m1.v checks against the course vga_adapter.v ports (color, x, y, write). It elaborates with stubs for the Altera memory and PLL, but not yet on the board.

## Mouse demo in Quartus (top_m2)
- Top-level entity: top_m2. Add rtl/*.v, course_vga/*.v and ps2/*.v. Do not add sim/.
- Pins: PS2_CLK and PS2_DAT are the standard names in DE1_SoC.qsf (also CLOCK_50, KEY, LEDR, VGA_*).
- Plug the mouse in before programming (or press KEY0 after plugging it in). LEDR0 on = mouse ready.
- top_m1 (KEY cursor) still works as a fallback: set it as the top-level entity instead.

## Not yet done
- top_m2 has not been run on the board yet.
- Fast mouse moves leave gaps in pen strokes (one pixel per packet). Line drawing fixes this later.
- MOVE_SHIFT in top_m2 sets mouse speed (1 = half speed). Change it if the cursor feels too fast/slow.
