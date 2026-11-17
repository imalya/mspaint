// AI-ASSISTED (Claude): PS/2 mouse 3-byte packet parser.
// Byte 0: [0] left, [1] right, [2] middle, [3] always 1, [4] X sign, [5] Y sign.
// Byte 1: X movement, Byte 2: Y movement. Signs are two's complement, 9-bit result.
// A byte-0 without bit 3 set is discarded so the parser can resync.
`timescale 1ns/1ps
module mouse_packet_parser (
    input            clk,
    input            resetn,
    input            rx_valid,        // one-clock pulse per received byte
    input      [7:0] rx_data,
    output reg       pkt_valid,       // one-clock pulse when a full packet is ready
    output reg [2:0] btn,
    output reg signed [8:0] dx,
    output reg signed [8:0] dy
);
    reg [1:0] count;                  // 0, 1, 2: which byte we expect next
    reg [7:0] b0, b1;

    always @(posedge clk) begin
        pkt_valid <= 0;
        if (!resetn) begin
            count <= 0;
        end else if (rx_valid) begin
            case (count)
                2'd0: if (rx_data[3]) begin     // ignore bytes that aren't a packet start
                          b0 <= rx_data;
                          count <= 1;
                      end
                2'd1: begin
                          b1 <= rx_data;
                          count <= 2;
                      end
                2'd2: begin
                          btn       <= b0[2:0];
                          dx        <= {b0[4], b1};     // sign bit + 8-bit magnitude
                          dy        <= {b0[5], rx_data};
                          pkt_valid <= 1;
                          count     <= 0;
                      end
                default: count <= 0;
            endcase
        end
    end
endmodule
