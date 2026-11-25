
`timescale 1ns/1ps
module fill_engine #(parameter H = 112) (
    input             clk,
    input             resetn,
    input             start,
    input      [7:0]  seed_x,
    input      [7:0]  seed_y,
    input      [2:0]  colour,
    output reg [14:0] raddr2,           // canvas read port (address)
    input      [2:0]  q2,               // canvas read port (data, 1 clock later)
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata,
    output            busy,
    output reg        done
);
    localparam DEPTH = 160 * H;
    localparam S_IDLE = 3'd0, S_SEED_W = 3'd1, S_SEED_C = 3'd2, S_POP = 3'd3,
               S_NEXT = 3'd4, S_N_W = 3'd5, S_N_C = 3'd6;
    reg [2:0]  state;

    reg [14:0] stack [0:DEPTH-1];       // entries are {y[6:0], x[7:0]}
    reg [14:0] sp;                      // number of entries on the stack
    reg [14:0] popped;                  // pixel whose neighbours we are checking
    reg [7:0]  nx, ny;                  // neighbour being checked
    reg [2:0]  dir;                     // 0 left, 1 right, 2 up, 3 down, 4 finished
    reg [2:0]  target, newc;
    reg [7:0]  vx, vy;                  // temporaries
    reg        ok;

    wire [7:0] px = popped[7:0];
    wire [7:0] py = {1'b0, popped[14:8]};

    assign busy = (state != S_IDLE);

    always @(posedge clk) begin
        we   <= 0;
        done <= 0;
        if (!resetn) begin
            state <= S_IDLE;
            sp    <= 0;
        end else case (state)
            S_IDLE: if (start) begin
                if (seed_y < H && seed_x < 160) begin
                    newc   <= colour;
                    nx     <= seed_x;
                    ny     <= seed_y;
                    raddr2 <= seed_y * 160 + seed_x;
                    state  <= S_SEED_W;
                end else
                    done <= 1;                         // seed outside the area
            end
            S_SEED_W: state <= S_SEED_C;               // wait for the RAM
            S_SEED_C: begin
                target <= q2;
                if (q2 == newc) begin                  // already that colour
                    done  <= 1;
                    state <= S_IDLE;
                end else begin
                    we <= 1; waddr <= ny * 160 + nx; wdata <= newc;
                    stack[sp] <= {ny[6:0], nx};         // sp is 0 here; one write
                    sp    <= sp + 15'd1;                // address keeps it a RAM block
                    state <= S_POP;
                end
            end
            S_POP: begin
                if (sp == 0) begin
                    done  <= 1;
                    state <= S_IDLE;
                end else begin
                    popped <= stack[sp - 1];
                    sp     <= sp - 1;
                    dir    <= 0;
                    state  <= S_NEXT;
                end
            end
            S_NEXT: begin
                if (dir == 3'd4) begin
                    state <= S_POP;
                end else begin
                    vx = px; vy = py; ok = 0;
                    case (dir)
                        3'd0: if (px != 0)     begin vx = px - 8'd1; ok = 1; end
                        3'd1: if (px != 159)   begin vx = px + 8'd1; ok = 1; end
                        3'd2: if (py != 0)     begin vy = py - 8'd1; ok = 1; end
                        default: if (py != H-1) begin vy = py + 8'd1; ok = 1; end
                    endcase
                    if (ok) begin
                        nx     <= vx;
                        ny     <= vy;
                        raddr2 <= vy * 160 + vx;
                        state  <= S_N_W;
                    end else
                        dir <= dir + 3'd1;             // neighbour off the edge
                end
            end
            S_N_W: state <= S_N_C;                     // wait for the RAM
            S_N_C: begin
                if (q2 == target) begin
                    we <= 1; waddr <= ny * 160 + nx; wdata <= newc;
                    stack[sp] <= {ny[6:0], nx};
                    sp <= sp + 1;
                end
                dir   <= dir + 3'd1;
                state <= S_NEXT;
            end
            default: state <= S_IDLE;
        endcase
    end
endmodule
