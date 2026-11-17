//This module takes the raw bytes coming from the mouse and assembles them into one complete movement-and-button report.
//A PS/2 mouse sends 3 bytes every time something happens (movement or a button press)
//Byte 0 - which buttons are pressed and some direction flags
//Byte 1 - how far it moved in x
//Byte 2 - how far it moved in y

`timescale 1ns/1ps
module mouse_packet_parser (
    input            clk,
    input            resetn,
    input            rx_valid,        // one-clock pulse per received byte
    input      [7:0] rx_data, //the byte
    output reg       pkt_valid,       // one-clock pulse when a full packet is ready
    output reg [2:0] btn, //3 button bits
    output reg signed [8:0] dx, //signed distance
    output reg signed [8:0] dy
);
    reg [1:0] count;                  // 0, 1, 2: which byte we expect next
    reg [7:0] b0, b1; //storage for the first two bytes because we cant output until the third byte arrives
//in byte 0, bit 3 is salways 1 for a real first byte
    always @(posedge clk) begin 
        pkt_valid <= 0; //no packet is ready
        if (!resetn) begin
            count <= 0;
        end else if (rx_valid) begin //if not in reset, do something on clocks where a new byte has arrived
            case (count) //pick what to do based on count
                2'd0: if (rx_data[3]) begin     // continue if the bit 3 of the incmoming byte is 1 on count = 0 
                          b0 <= rx_data; //saves byte
                          count <= 1; //move on
                      end
                2'd1: begin //count = 1, byte 1
                          b1 <= rx_data;
                          count <= 2;
                      end
                2'd2: begin
                    btn       <= b0[2:0]; //takes the 3 lowest bits of the first byte (left, right, and middle buttons).
                          dx        <= {b0[4], b1};     // glues the x sign bit (bit 4 of byte 0) onto the front of byte 1, making a 9-bit number
                    dy        <= {b0[5], rx_data};//does the same for y, using bit 5 of byte 0 and the byte that just arrived.
                          pkt_valid <= 1;//raises the “packet ready” flag
                          count     <= 0;//goes back to waiting for the next packet’s first byte
                      end
                default: count <= 0; //A safety net for any count value not listed (only 3 is possible)
            endcase
        end
    end
endmodule
