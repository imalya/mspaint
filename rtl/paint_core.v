// paint_core.v -- tool FSM + line/eraser engines + write mux.
// Connect plot/plot_x/plot_y/plot_color to canvas_ram's write port
// (addr = plot_y*160 + plot_x). Tie pen_* to your pen_engine's outputs
// (pen_en tells it when to draw, `color` is the selected color).
module paint_core (
    input            clk,
    input            resetn,
    input            btn_left,
    input            tb_hit,
    input      [3:0]  tb_idx,
    input      [7:0]  cx,
    input      [6:0]  cy,
    // from pen_engine
    input            pen_plot,
    input      [7:0]  pen_x,
    input      [6:0]  pen_y,
    output           pen_en,
    // state for toolbar highlight etc.
    output     [1:0]  tool,
    output     [2:0]  color,
    // canvas write port
    output           plot,
    output     [7:0]  plot_x,
    output     [6:0]  plot_y,
    output     [2:0]  plot_color
);
    wire [7:0] start_x;
    wire [6:0] start_y;
    wire       erase_en, line_start;

    tool_select_fsm u_fsm (
        .clk(clk), .resetn(resetn), .btn_left(btn_left),
        .tb_hit(tb_hit), .tb_idx(tb_idx), .cx(cx), .cy(cy),
        .tool(tool), .color(color), .start_x(start_x), .start_y(start_y),
        .pen_en(pen_en), .erase_en(erase_en), .line_start(line_start)
    );

    // ---- line engine ----
    wire [7:0] ln_x; wire [6:0] ln_y; wire [2:0] ln_c;
    wire       ln_plot, ln_busy, ln_done;
    line_engine u_line (
        .clk(clk), .resetn(resetn), .start(line_start),
        .x0_in(start_x), .y0_in(start_y), .x1_in(cx), .y1_in(cy),
        .color_in(color),
        .x_out(ln_x), .y_out(ln_y), .color_out(ln_c),
        .plot(ln_plot), .busy(ln_busy), .done(ln_done)
    );

    // ---- eraser engine: stamp each time the cursor moves while erasing ----
    reg        was_en;
    reg [7:0]  lx;
    reg [6:0]  ly;
    wire       er_busy;
    wire       erase_go = erase_en & ~er_busy &
                          (~was_en | (cx != lx) | (cy != ly));
    always @(posedge clk) begin
        if (!resetn) begin was_en <= 1'b0; lx <= 0; ly <= 0; end
        else begin
            was_en <= erase_en;
            if (erase_go) begin lx <= cx; ly <= cy; end
        end
    end

    wire [7:0] er_x; wire [6:0] er_y; wire [2:0] er_c; wire er_plot;
    eraser_engine #(.SIZE(4)) u_erase (
        .clk(clk), .resetn(resetn), .start(erase_go), .cx(cx), .cy(cy),
        .x_out(er_x), .y_out(er_y), .color_out(er_c),
        .plot(er_plot), .busy(er_busy)
    );

    // ---- write mux (only one source is active at a time) ----
    assign plot       = ln_plot | er_plot | pen_plot;
    assign plot_x     = ln_plot ? ln_x : er_plot ? er_x : pen_x;
    assign plot_y     = ln_plot ? ln_y : er_plot ? er_y : pen_y;
    assign plot_color = ln_plot ? ln_c : er_plot ? er_c : color;
endmodule
