// color picker. 
// When you click on the color strip at the bottom of the screen
//it figures out which color you clicked and tells the rest of the design.

//The bottom rows of the canvas (y = 112 and below) hold a strip of 8 colored squares
//The screen is 160 pixels wide, so each swatch is 160 / 8 = 20 pixels wide.
//If you click while the cursor is over the strip
//this module works out which swatch you’re on and outputs that color.

`timescale 1ns/1ps
module toolbar (
    input            clk,
    input            resetn,
    input      [7:0] cursor_x,      // 0..159 comes from the mouse tracker
    input      [7:0] cursor_y,      // 0..119  mouse tracker
    input            button, //mouse tracker
    output reg       sel_valid,      // one-clock pulse on a swatch click, pulses for one clock when a color was just picked, which means “new color, use it.”
    output reg [2:0] sel_colour //picked color (3 bits, one of the 8 colors)
);
    localparam PALETTE_TOP = 112;    // first row of the palette
    //The canvas is 120 rows tall (0 to 119), and the palette uses the bottom 8 rows (112 to 119).
    //So “y is 112 or more” means “the cursor is on the palette.”
    reg button_d;  //The _d means “delayed.” 
    //It stores what button was on the previous clock
    //Each clock it records what button was, 
    //so on the next clock you can compare “now” with “a moment ago.”

    always @(posedge clk) begin
        sel_valid <= 0; //The default each clock is “no new color.”
        if (!resetn) begin
            button_d <= 0;//clear the remebered statement
        end else begin
            button_d <= button;
            //save current button value
            // act on the press (rising edge) while the cursor is on the palette
            if (button && !button_d && cursor_y >= PALETTE_TOP) begin
                //is button down, was it up on previous clock, the cursos is on the pallete rows
                sel_colour <= cursor_x / 20;        // 0..7
                //The canvas is 160 pixels wide and there are 8 swatches, so each is 20 pixels wide. 
                //Dividing by 20 and dropping the remainder gives the swatch number:
                sel_valid  <= 1;
            end
        end
    end
endmodule
