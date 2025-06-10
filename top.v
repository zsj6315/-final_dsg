module top(
    input clk_100MHz,       // 100MHz系统时钟
    input reset,             // 复位按钮
    input [3:0] row_sel,     // 行选择开关
    input [3:0] col_sel,     // 列选择开关
    input [3:0] num_in,      // 数字输入开关
    input enter,             // 确认输入按钮
    input clear,             // 清除按钮
    input new_game,          // 新游戏按钮
    
    // VGA输出接口
    output hsync,            // 行同步
    output vsync,            // 场同步
    output [3:0] vga_red,    // VGA红色
    output [3:0] vga_green,  // VGA绿色
    output [3:0] vga_blue    // VGA蓝色
);

// 时钟分频：100MHz -> 25.175MHz (VGA标准时钟)
wire clk_vga;
clk_wiz_0 vga_clk_gen(
    .clk_in1(clk_100MHz),
    .clk_out1(clk_vga)
);

// VGA时序控制
wire [9:0] pixel_x;
wire [9:0] pixel_y;
wire video_on;
vga_controller vga_ctrl(
    .clk(clk_vga),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .video_on(video_on),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y)
);

// 数独游戏核心
wire [15:0] grid;           // 一维表示的4x4网格
wire [1:0] cursor_row;
wire [1:0] cursor_col;
wire error_flag;
wire win_flag;
wire [15:0] fixed_mask;     // 固定数字掩码

sudoku_game game_core(
    .clk(clk_100MHz),
    .reset(reset),
    .new_game(new_game),
    .row_sel(row_sel),
    .col_sel(col_sel),
    .num_in(num_in),
    .enter(enter),
    .clear(clear),
    .grid(grid),
    .cursor_row(cursor_row),
    .cursor_col(cursor_col),
    .error_flag(error_flag),
    .win_flag(win_flag),
    .fixed_mask(fixed_mask)
);

// VGA渲染
vga_render renderer(
    .clk(clk_vga),
    .video_on(video_on),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .grid(grid),            // 传递一维网格
    .cursor_row(cursor_row),
    .cursor_col(cursor_col),
    .error_flag(error_flag),
    .win_flag(win_flag),
    .fixed_mask(fixed_mask),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue)
);

endmodule