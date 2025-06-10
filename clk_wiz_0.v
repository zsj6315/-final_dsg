module clk_wiz_0(
    input  clk_in1,   // 100 MHz 输入时钟
    input  reset,     // 高电平复位
    output clk_out1,  // 25.175 MHz 输出时钟
    output locked     // 时钟锁定信号
);

// MMCM 原语实例化
MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),    // Jitter programming (OPTIMIZED, HIGH, LOW)
    .CLKFBOUT_MULT_F(10.0),     // Multiply value for all CLKOUT (2.000-64.000).
    .CLKFBOUT_PHASE(0.0),       // Phase offset in degrees of CLKFB (-360.000-360.000).
    .CLKIN1_PERIOD(10.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    
    // CLKOUT0 configuration
    .CLKOUT0_DIVIDE_F(39.75),   // Divide amount for CLKOUT0 (1.000-128.000).
    .CLKOUT0_DUTY_CYCLE(0.5),   // Duty cycle for CLKOUT0 (0.01-0.99).
    .CLKOUT0_PHASE(0.0),        // Phase offset for CLKOUT0 (-360.000-360.000).
    
    // 其他输出时钟配置 (未使用)
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0.0),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0.0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0.0),
    
    .REF_JITTER1(0.010),        // Reference input jitter in UI (0.000-0.999).
    .STARTUP_WAIT("FALSE")      // Delays DONE until MMCM is locked (FALSE, TRUE)
)
mmcm_inst (
    // Clock Outputs
    .CLKOUT0(clk_out1),         // 25.175 MHz
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    
    // Feedback
    .CLKFBOUT(),                // 1-bit output: Feedback clock
    .CLKFBOUTB(),
    
    // Status
    .LOCKED(locked),            // 1-bit output: LOCK
    
    // Inputs
    .CLKIN1(clk_in1),           // 1-bit input: Input clock
    
    // Control
    .PWRDWN(1'b0),              // 1-bit input: Power-down
    .RST(reset),                // 1-bit input: Reset
    
    // Feedback
    .CLKFBIN()                  // 1-bit input: Feedback clock
);

endmodule