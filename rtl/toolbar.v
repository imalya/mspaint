// AI-ASSISTED (Claude): toolbar hit-testing.
// The bottom 8 rows of the canvas are a palette: 8 swatches, 20 pixels wide each.
// Clicking a swatch (left button, cursor in those rows) selects that colour.
// Colour 0 (black) is the first swatch.
`timescale 1ns/1ps
module toolbar (
    input            clk,
    input            resetn,
    input      [7:0] cursor_x,      // 0..159
    input      [7:0] cursor_y,      // 0..119
    input            button,
    output reg       sel_valid,      // one-clock pulse on a swatch click
    output reg [2:0] sel_colour
);
    localparam PALETTE_TOP = 112;    // first row of the palette
    reg button_d;

    always @(posedge clk) begin
        sel_valid <= 0;
        if (!resetn) begin
            button_d <= 0;
        end else begin
            button_d <= button;
            // act on the press (rising edge) while the cursor is on the palette
            if (button && !button_d && cursor_y >= PALETTE_TOP) begin
                sel_colour <= cursor_x / 20;        // 0..7
                sel_valid  <= 1;
            end
        end
    end
endmodule
