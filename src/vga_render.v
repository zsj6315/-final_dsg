module vga_render(
    input clk,
    input video_on,
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input [15:0] grid,  // 修改为一维数组表示4x4网格
    input [1:0] cursor_row,
    input [1:0] cursor_col,
    input error_flag,
    input win_flag,
    input [15:0] fixed_mask,
    output reg [3:0] vga_red,
    output reg [3:0] vga_green,
    output reg [3:0] vga_blue
);

// 显示参数
parameter BOARD_X = 160;  // 棋盘左上角X坐标
parameter BOARD_Y = 100;  // 棋盘左上角Y坐标
parameter CELL_SIZE = 80; // 格子大小
parameter GRID_SIZE = 4;  // 4x4网格
parameter BOARD_WIDTH = CELL_SIZE * GRID_SIZE;
parameter BOARD_HEIGHT = CELL_SIZE * GRID_SIZE;

// 颜色定义
parameter BG_COLOR     = 12'h369;  // 背景色 (深蓝)
parameter GRID_COLOR   = 12'hFFF;  // 网格线 (白色)
parameter TEXT_COLOR   = 12'hFFF;  // 文字 (白色)
parameter FIXED_COLOR  = 12'hF00;  // 固定数字 (红色)
parameter CURSOR_COLOR = 12'h0F0;  // 光标 (绿色)
parameter ERROR_COLOR  = 12'hF0F;  // 错误提示 (紫色)
parameter WIN_COLOR    = 12'h0FF;  // 胜利提示 (青色)

// 内部信号
wire [9:0] board_rel_x = (pixel_x >= BOARD_X) ? (pixel_x - BOARD_X) : 10'd0;
wire [9:0] board_rel_y = (pixel_y >= BOARD_Y) ? (pixel_y - BOARD_Y) : 10'd0;
wire in_board = (pixel_x >= BOARD_X) && (pixel_x < BOARD_X + BOARD_WIDTH) &&
               (pixel_y >= BOARD_Y) && (pixel_y < BOARD_Y + BOARD_HEIGHT);

// 当前格子坐标
wire [1:0] cell_x = board_rel_x / CELL_SIZE;  // 自动取整
wire [1:0] cell_y = board_rel_y / CELL_SIZE;  // 自动取整

// 从一维网格中获取值的函数
function [3:0] get_cell_value;
    input [1:0] row;
    input [1:0] col;
    begin
        case(row)
            2'd0: get_cell_value = grid[col*4 +: 4];         // 第0行 [3:0], [7:4], [11:8], [15:12]
            2'd1: get_cell_value = grid[col*4 + 16 +: 4];    // 第1行
            2'd2: get_cell_value = grid[col*4 + 32 +: 4];    // 第2行
            2'd3: get_cell_value = grid[col*4 + 48 +: 4];    // 第3行
            default: get_cell_value = 4'd0;
        endcase
    end
endfunction

// 当前格子的值
wire [3:0] cell_value = get_cell_value(cell_y, cell_x);

// 是否在光标位置
wire in_cursor = (cell_x == cursor_col) && (cell_y == cursor_row) && 
                (board_rel_x % CELL_SIZE > 5) && (board_rel_x % CELL_SIZE < CELL_SIZE - 5) &&
                (board_rel_y % CELL_SIZE > 5) && (board_rel_y % CELL_SIZE < CELL_SIZE - 5);

// 是否在网格线上
wire grid_line = ((board_rel_x % CELL_SIZE < 2) || (board_rel_x % CELL_SIZE > CELL_SIZE - 2) ||
                 (board_rel_y % CELL_SIZE < 2) || (board_rel_y % CELL_SIZE > CELL_SIZE - 2)) ||
                ((board_rel_x % (CELL_SIZE * 2) < 4) && (board_rel_x % (CELL_SIZE * 2) > CELL_SIZE - 4)) ||
                ((board_rel_y % (CELL_SIZE * 2) < 4) && (board_rel_y % (CELL_SIZE * 2) > CELL_SIZE - 4));

// 数字显示逻辑
wire in_cell = !grid_line && in_board;
wire [3:0] digit = (cell_value != 0) ? cell_value : 4'd0;
wire fixed_cell = fixed_mask[cell_y*4 + cell_x];

// 字符像素坐标
wire [2:0] char_x = (board_rel_x % CELL_SIZE) >> 3; // 除以8 (右移3位)
wire [2:0] char_y = (board_rel_y % CELL_SIZE) >> 3; // 除以8 (右移3位)

// 字符ROM查找逻辑
reg [7:0] char_line; // 当前字符行数据
always @(*) begin
    case({digit, char_y})
        // 数字0
        7'b0000_000: char_line = 8'b00111100; // 行0
        7'b0000_001: char_line = 8'b01000010; // 行1
        7'b0000_010: char_line = 8'b01000010; // 行2
        7'b0000_011: char_line = 8'b01000010; // 行3
        7'b0000_100: char_line = 8'b01000010; // 行4
        7'b0000_101: char_line = 8'b01000010; // 行5
        7'b0000_110: char_line = 8'b01000010; // 行6
        7'b0000_111: char_line = 8'b00111100; // 行7
        
        // 数字1
        7'b0001_000: char_line = 8'b00011000; // 行0
        7'b0001_001: char_line = 8'b00111000; // 行1
        7'b0001_010: char_line = 8'b00011000; // 行2
        7'b0001_011: char_line = 8'b00011000; // 行3
        7'b0001_100: char_line = 8'b00011000; // 行4
        7'b0001_101: char_line = 8'b00011000; // 行5
        7'b0001_110: char_line = 8'b00011000; // 行6
        7'b0001_111: char_line = 8'b01111110; // 行7
        
        // 数字2
        7'b0010_000: char_line = 8'b00111100; // 行0
        7'b0010_001: char_line = 8'b01000010; // 行1
        7'b0010_010: char_line = 8'b00000010; // 行2
        7'b0010_011: char_line = 8'b00000100; // 行3
        7'b0010_100: char_line = 8'b00011000; // 行4
        7'b0010_101: char_line = 8'b00100000; // 行5
        7'b0010_110: char_line = 8'b01000000; // 行6
        7'b0010_111: char_line = 8'b01111110; // 行7
        
        // 数字3
        7'b0011_000: char_line = 8'b00111100; // 行0
        7'b0011_001: char_line = 8'b01000010; // 行1
        7'b0011_010: char_line = 8'b00000010; // 行2
        7'b0011_011: char_line = 8'b00011100; // 行3
        7'b0011_100: char_line = 8'b00000010; // 行4
        7'b0011_101: char_line = 8'b00000010; // 行5
        7'b0011_110: char_line = 8'b01000010; // 行6
        7'b0011_111: char_line = 8'b00111100; // 行7
        
        // 数字4
        7'b0100_000: char_line = 8'b00000100; // 行0
        7'b0100_001: char_line = 8'b00001100; // 行1
        7'b0100_010: char_line = 8'b00010100; // 行2
        7'b0100_011: char_line = 8'b00100100; // 行3
        7'b0100_100: char_line = 8'b01000100; // 行4
        7'b0100_101: char_line = 8'b01111110; // 行5
        7'b0100_110: char_line = 8'b00000100; // 行6
        7'b0100_111: char_line = 8'b00000100; // 行7
        
        // 默认情况（空格或无效数字）
        default: char_line = 8'b00000000;
    endcase
end

// 字符像素提取 - 注意位顺序调整 (MSB first)
wire char_pixel = (cell_value != 0) ? char_line[7 - char_x] : 1'b0;

// 渲染逻辑
always @(posedge clk) begin
    if (!video_on) begin
        // 消隐期间输出黑色
        vga_red   <= 4'b0000;
        vga_green <= 4'b0000;
        vga_blue  <= 4'b0000;
    end else begin
        // 默认背景色
        vga_red   <= BG_COLOR[11:8];
        vga_green <= BG_COLOR[7:4];
        vga_blue  <= BG_COLOR[3:0];
        
        // 游戏板背景 (覆盖默认背景)
        if (in_board) begin
            vga_red   <= 4'b0000;
            vga_green <= 4'b0000;
            vga_blue  <= 4'b0000;
        end
        
        // 网格线 (覆盖背景)
        if (in_board && grid_line) begin
            vga_red   <= GRID_COLOR[11:8];
            vga_green <= GRID_COLOR[7:4];
            vga_blue  <= GRID_COLOR[3:0];
        end
        
        // 光标 (覆盖网格线)
        if (in_cursor) begin
            vga_red   <= CURSOR_COLOR[11:8];
            vga_green <= CURSOR_COLOR[7:4];
            vga_blue  <= CURSOR_COLOR[3:0];
        end
        
        // 数字显示 (覆盖光标)
        if (in_cell && char_pixel) begin
            if (fixed_cell) begin
                // 固定数字 - 红色
                vga_red   <= FIXED_COLOR[11:8];
                vga_green <= FIXED_COLOR[7:4];
                vga_blue  <= FIXED_COLOR[3:0];
            end else begin
                // 玩家输入数字 - 白色
                vga_red   <= TEXT_COLOR[11:8];
                vga_green <= TEXT_COLOR[7:4];
                vga_blue  <= TEXT_COLOR[3:0];
            end
        end
        
        // 错误状态显示 (覆盖所有)
        if (error_flag && (pixel_y < 30)) begin
            vga_red   <= ERROR_COLOR[11:8];
            vga_green <= ERROR_COLOR[7:4];
            vga_blue  <= ERROR_COLOR[3:0];
        end 
        // 胜利状态显示 (覆盖所有)
        else if (win_flag && (pixel_y < 30)) begin
            vga_red   <= WIN_COLOR[11:8];
            vga_green <= WIN_COLOR[7:4];
            vga_blue  <= WIN_COLOR[3:0];
        end
    end
end

endmodule