// AI-ASSISTED (Claude): PS/2 mouse start-up.
// The course PS2_Controller is used with INITIALIZE_MOUSE = 1, so the core itself
// sends 0xF4 (enable data reporting) after reset. The mouse answers with 0xFA.
// This block waits for that 0xFA and only then lets bytes through to the packet
// parser. Without it, the parser would treat 0xFA (bit 3 = 1) as the first byte
// of a packet and every packet after it would be misaligned.
// Press reset (KEY0) to send 0xF4 again, e.g. after plugging the mouse in.
`timescale 1ns/1ps
module mouse_init (
    input            clk,
    input            resetn,
    input            rx_valid,
    input      [7:0] rx_data,
    output reg       init_done
);
    always @(posedge clk) begin
        if (!resetn)
            init_done <= 0;
        else if (rx_valid && rx_data == 8'hFA)
            init_done <= 1;
    end
endmodule
