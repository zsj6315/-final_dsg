module sudoku_game(
    input clk,
    input reset,
    input new_game,
    input [3:0] row_sel,
    input [3:0] col_sel,
    input [3:0] num_in,
    input enter,
    input clear,
    
    // 修改为64位一维数组表示网格（4行x4列x4位）
    output reg [63:0] grid,  // [63:60] row3 col0, [59:56] row3 col1, ... [3:0] row0 col3
    output reg [1:0] cursor_row,
    output reg [1:0] cursor_col,
    output reg error_flag,
    output reg win_flag,
    output reg [15:0] fixed_mask  // 16位掩码（每单元1位）
);

// 游戏状态定义
parameter IDLE = 2'b00;
parameter PLAY = 2'b01;
parameter WIN  = 2'b10;
parameter ERROR_ST = 2'b11;

reg [1:0] state;
reg [63:0] puzzle; // 64位初始谜题

// 循环变量声明
integer i, j, r, c, bi, bj, ri, rj;

// 从64位数组中获取网格值（每单元4位）
function [3:0] get_grid_value;
    input [1:0] row;
    input [1:0] col;
    begin
        // 计算单元位置: (row * 16) + (col * 4)
        get_grid_value = grid[row*16 + col*4 +: 4];
    end
endfunction

// 设置网格值（返回64位新网格）
function [63:0] set_grid_value;
    input [1:0] row;
    input [1:0] col;
    input [3:0] value;
    reg [63:0] temp;
    begin
        temp = grid;
        temp[row*16 + col*4 +: 4] = value;
        set_grid_value = temp;
    end
endfunction

// 光标移动逻辑
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cursor_row <= 0;
        cursor_col <= 0;
    end else begin
        if (row_sel[0] && cursor_row > 0) cursor_row <= cursor_row - 1;
        if (row_sel[1] && cursor_row < 3) cursor_row <= cursor_row + 1;
        if (col_sel[0] && cursor_col > 0) cursor_col <= cursor_col - 1;
        if (col_sel[1] && cursor_col < 3) cursor_col <= cursor_col + 1;
    end
end

// 初始化游戏
always @(posedge clk or posedge reset) begin
    if (reset || new_game) begin
        // 64位初始谜题 (行优先存储)
        puzzle <= {
            // 行3 (高位)
            4'd0, 4'd0, 4'd0, 4'd4,   // col0, col1, col2, col3
            // 行2
            4'd0, 4'd0, 4'd3, 4'd0,
            // 行1
            4'd0, 4'd2, 4'd0, 4'd0,
            // 行0 (低位)
            4'd1, 4'd0, 4'd0, 4'd0
        };
        
        // 固定数字掩码 (行优先: bit15=row3col3, bit0=row0col0)
        fixed_mask <= 16'b1000_0100_0010_0001; // 对角线固定
        
        grid <= puzzle;
        state <= PLAY;
        error_flag <= 0;
        win_flag <= 0;
    end
end

// 输入处理
reg [63:0] new_grid;
always @(posedge clk) begin
    if (state == PLAY) begin
        if (enter) begin
            if (!fixed_mask[cursor_row*4 + cursor_col]) begin
                if (num_in >= 1 && num_in <= 4) begin
                    new_grid = set_grid_value(cursor_row, cursor_col, num_in);
                    grid <= new_grid;
                    error_flag <= 0;
                end else begin
                    error_flag <= 1;
                end
            end
        end else if (clear) begin
            if (!fixed_mask[cursor_row*4 + cursor_col]) begin
                new_grid = set_grid_value(cursor_row, cursor_col, 4'd0);
                grid <= new_grid;
                error_flag <= 0;
            end
        end
    end
end

// 数独验证逻辑
reg valid;
reg [3:0] row_check [0:3];
reg [3:0] col_check [0:3];
reg [3:0] box_check [0:3];
reg [3:0] cell_val;

always @(*) begin
    valid = 1; // 默认有效

    // 初始化检查数组
    for (i = 0; i < 4; i = i + 1) begin
        row_check[i] = 0;
        col_check[i] = 0;
        box_check[i] = 0;
    end

    // 检查行和列
    for (r = 0; r < 4; r = r + 1) begin
        for (c = 0; c < 4; c = c + 1) begin
            cell_val = get_grid_value(r, c);
            
            if (cell_val != 0) begin
                // 检查行冲突
                if (row_check[r][cell_val-1]) begin
                    valid = 0;
                end else begin
                    row_check[r][cell_val-1] = 1;
                end
                
                // 检查列冲突
                if (col_check[c][cell_val-1]) begin
                    valid = 0;
                end else begin
                    col_check[c][cell_val-1] = 1;
                end
            end
        end
    end
    
    // 检查2x2子网格
    for (bi = 0; bi < 2; bi = bi + 1) begin
        for (bj = 0; bj < 2; bj = bj + 1) begin
            // 初始化box检查数组
            for (i = 0; i < 4; i = i + 1) begin
                box_check[i] = 0;
            end
            
            for (ri = 0; ri < 2; ri = ri + 1) begin
                for (rj = 0; rj < 2; rj = rj + 1) begin
                    r = bi*2 + ri;
                    c = bj*2 + rj;
                    cell_val = get_grid_value(r, c);
                    
                    if (cell_val != 0) begin
                        if (box_check[cell_val-1]) begin
                            valid = 0;
                        end else begin
                            box_check[cell_val-1] = 1;
                        end
                    end
                end
            end
        end
    end
end

// 胜利条件检查
reg win;
reg all_filled;
always @(*) begin
    win = 1;
    all_filled = 1;
    
    // 检查所有格子是否已填满
    for (r = 0; r < 4; r = r + 1) begin
        for (c = 0; c < 4; c = c + 1) begin
            if (get_grid_value(r, c) == 0) begin
                all_filled = 0;
                win = 0;
            end
        end
    end
    
    // 如果全部填满则检查有效性
    if (all_filled) begin
        win = valid;
    end
end

// 定期检查游戏状态
reg [23:0] check_counter;
always @(posedge clk) begin
    if (reset || new_game) begin
        check_counter <= 0;
        error_flag <= 0;
        win_flag <= 0;
    end else if (state == PLAY) begin
        check_counter <= check_counter + 1;
        if (&check_counter) begin // 计数器达到最大值
            error_flag <= !valid;
            win_flag <= win;
            if (win) begin
                state <= WIN;
            end
        end
    end
end

endmodule