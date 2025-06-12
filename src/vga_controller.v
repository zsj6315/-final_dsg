module vga_controller(
    input clk,        // 25.175MHz VGA时钟
    input reset,
    output reg hsync,
    output reg vsync,
    output reg video_on,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y
);

// VGA 640x480时序参数
parameter HD = 640;  // 水平显示区域
parameter HF = 16;   // 水平前沿
parameter HB = 48;   // 水平后沿
parameter HR = 96;   // 水平同步脉冲
parameter VD = 480;  // 垂直显示区域
parameter VF = 10;   // 垂直前沿
parameter VB = 33;   // 垂直后沿
parameter VR = 2;    // 垂直同步脉冲

// 水平计数器 (0-799)
reg [9:0] h_count;

// 垂直计数器 (0-524)
reg [9:0] v_count;

// 内部信号
wire h_end, v_end;

// 水平计数结束条件
assign h_end = (h_count == (HD + HF + HB + HR - 1));

// 垂直计数结束条件
assign v_end = (v_count == (VD + VF + VB + VR - 1));

// 水平计数器逻辑
always @(posedge clk or posedge reset) begin
    if (reset) begin
        h_count <= 0;
    end else begin
        if (h_end) begin
            h_count <= 0;
        end else begin
            h_count <= h_count + 1;
        end
    end
end

// 垂直计数器逻辑
always @(posedge clk or posedge reset) begin
    if (reset) begin
        v_count <= 0;
    end else if (h_end) begin
        if (v_end) begin
            v_count <= 0;
        end else begin
            v_count <= v_count + 1;
        end
    end
end

// 同步信号生成
always @(posedge clk) begin
    // 水平同步信号
    hsync <= ~(h_count >= (HD + HB) && h_count < (HD + HB + HR));
    
    // 垂直同步信号
    vsync <= ~(v_count >= (VD + VB) && v_count < (VD + VB + VR));
    
    // 视频有效信号
    video_on <= (h_count < HD) && (v_count < VD);
    
    // 当前像素坐标
    pixel_x <= h_count;
    pixel_y <= v_count;
end

endmodule