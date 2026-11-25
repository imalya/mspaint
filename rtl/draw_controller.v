// AI-ASSISTED (Claude): connects the mouse to the drawing engines.
// tool: 0 pen, 1 eraser, 2 line, 3 rectangle, 4 fill
//   pen / eraser: draw while the left button is held
//   line / rectangle: press = first point, release = second point, then draw
//   fill: click inside a region
//   clear (separate input): wipe the canvas
// Only one engine writes at a time; a press is ignored while an engine is busy.
// Clicks on the palette rows (y > YMAX) never start a drawing.
`timescale 1ns/1ps
module draw_controller #(parameter YMAX = 111) (
    input             clk,
    input             resetn,
    input      [2:0]  tool,
    input      [2:0]  colour,
    input      [7:0]  cursor_x,
    input      [7:0]  cursor_y,
    input             button,
    input             clear,
    output     [14:0] raddr2,           // second canvas read port (fill)
    input      [2:0]  q2,
    output reg        we,
    output reg [14:0] waddr,
    output reg [2:0]  wdata,
    output            busy
);
    localparam T_PEN = 3'd0, T_ERASE = 3'd1, T_LINE = 3'd2, T_RECT = 3'd3, T_FILL = 3'd4;

    wire in_canvas = (cursor_y <= YMAX);

    // ---------- button events ----------
    reg button_d, clear_d;
    wire press       =  button & ~button_d;
    wire release_evt = ~button &  button_d;
    wire clear_press =  clear  & ~clear_d;

    reg        dragging;
    reg [7:0]  ax, ay, ex, ey;          // first point, second point
    reg        start_line, start_rect, start_fill, start_clear;

    wire line_busy, rect_busy, fill_busy, clear_busy;
    assign busy = line_busy | rect_busy | fill_busy | clear_busy |
                  start_line | start_rect | start_fill | start_clear;

    always @(posedge clk) begin
        start_line <= 0; start_rect <= 0; start_fill <= 0; start_clear <= 0;
        if (!resetn) begin
            button_d <= 0; clear_d <= 0; dragging <= 0;
            ax <= 0; ay <= 0; ex <= 0; ey <= 0;
        end else begin
            button_d <= button;
            clear_d  <= clear;
            if (clear_press && !busy) begin
                start_clear <= 1;
                dragging    <= 0;
            end else if (press && in_canvas && !busy) begin
                if (tool == T_LINE || tool == T_RECT) begin
                    dragging <= 1;
                    ax <= cursor_x;
                    ay <= cursor_y;
                end else if (tool == T_FILL) begin
                    start_fill <= 1;
                    ex <= cursor_x;
                    ey <= cursor_y;
                end
            end else if (release_evt && dragging) begin
                dragging <= 0;
                ex <= cursor_x;
                ey <= in_canvas ? cursor_y : YMAX;     // keep off the palette
                if (tool == T_LINE)      start_line <= 1;
                else if (tool == T_RECT) start_rect <= 1;
            end
        end
    end

    // ---------- engines ----------
    wire        pen_we, er_we, line_we, rect_we, fill_we, clr_we;
    wire [14:0] pen_a,  er_a,  line_a,  rect_a,  fill_a,  clr_a;
    wire [2:0]  pen_d,  er_d,  line_d,  rect_d,  fill_d,  clr_d;

    pen_engine pen (.clk(clk), .resetn(resetn),
        .button(button && in_canvas && tool == T_PEN && !busy),
        .cursor_x(cursor_x), .cursor_y(cursor_y), .colour(colour),
        .we(pen_we), .waddr(pen_a), .wdata(pen_d));

    eraser_engine #(.YMAX(YMAX)) eraser (.clk(clk), .resetn(resetn),
        .active(button && in_canvas && tool == T_ERASE && !busy),
        .cursor_x(cursor_x), .cursor_y(cursor_y),
        .we(er_we), .waddr(er_a), .wdata(er_d));

    line_engine line (.clk(clk), .resetn(resetn), .start(start_line),
        .x0(ax), .y0(ay), .x1(ex), .y1(ey), .colour(colour),
        .we(line_we), .waddr(line_a), .wdata(line_d), .busy(line_busy), .done());

    rect_engine rect (.clk(clk), .resetn(resetn), .start(start_rect),
        .x0(ax), .y0(ay), .x1(ex), .y1(ey), .colour(colour),
        .we(rect_we), .waddr(rect_a), .wdata(rect_d), .busy(rect_busy), .done());

    fill_engine #(.H(YMAX + 1)) fill (.clk(clk), .resetn(resetn), .start(start_fill),
        .seed_x(ex), .seed_y(ey), .colour(colour),
        .raddr2(raddr2), .q2(q2),
        .we(fill_we), .waddr(fill_a), .wdata(fill_d), .busy(fill_busy), .done());

    clear_engine clr (.clk(clk), .resetn(resetn), .start(start_clear),
        .we(clr_we), .waddr(clr_a), .wdata(clr_d), .busy(clear_busy), .done());

    // ---------- one canvas write port: pick the engine that is writing ----------
    always @(*) begin
        if (clr_we)       begin we = 1'b1;   waddr = clr_a;  wdata = clr_d;  end
        else if (fill_we) begin we = 1'b1;   waddr = fill_a; wdata = fill_d; end
        else if (line_we) begin we = 1'b1;   waddr = line_a; wdata = line_d; end
        else if (rect_we) begin we = 1'b1;   waddr = rect_a; wdata = rect_d; end
        else if (er_we)   begin we = 1'b1;   waddr = er_a;   wdata = er_d;   end
        else              begin we = pen_we; waddr = pen_a;  wdata = pen_d;  end
    end
endmodule
