
`timescale 1ns/1ps
module mouse_tracker (
    input             clk,
    input             resetn,
    input             pkt_valid, //from packet parser 
    input      [2:0]  btn, //from packet parser 
    input signed [8:0] dx,  //from packet parser 
    input signed [8:0] dy,//from packet parser 
    output reg [7:0]  cursor_x,      // 0..159
    output reg [7:0]  cursor_y,      // 0..119 cursor postion 
    output reg        button         // left button held = 1
);
    localparam W = 160, H = 120;

    //adding the mouse movement to the cursor position
    //but the result can land outside the screen.
    //ex. Moving left 5 from x = 3 gives 3 + (-5) = -2. 
    //the variable that holds the answer has to be able to store a negative number
    reg signed [10:0] nx, ny; //11 bits for the new x and y because they ar esigned 
    //dx can be anywhere from -256 to +255
    //and the cursor can be anywhere from 0 to 159
    //so the answer can range from -256 to about 414. 
    
    always @(posedge clk) begin
        if (!resetn) begin //on reset put the cursor in the middle of the screen and mark the button as not pressed
            cursor_x <= 80;
            cursor_y <= 60;
            button   <= 0;
        end else if (pkt_valid) begin //if a full packet has arrived 
            button <= btn[0]; //bit 0 of btn is the left button
            nx = $signed({2'b00, cursor_x}) + dx; //new x = old x + movement 
            ny = $signed({2'b00, cursor_y}) - dy;
            // subtracted because the mouse and the screen disagree about direction. 
            //The mouse reports “up” as a positive number, 
            //but on the screen, y = 0 is the top row
            //so going up means y gets smaller.
            if (nx < 0)        cursor_x <= 0; //went off the left edge?
            else if (nx > W-1) cursor_x <= W-1; //went off the right edge? stop at 159
            else               cursor_x <= nx[7:0]; //otherwsie use it
            if (ny < 0)        cursor_y <= 0;
            else if (ny > H-1) cursor_y <= H-1;
            else               cursor_y <= ny[7:0];
        end
    end
endmodule
