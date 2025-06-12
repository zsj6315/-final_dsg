iverilog -o .\build\wave.out .\src\clk_wiz_0.v  .\src\sudoku_game.v .\src\top.v .\src\vga_controller.v .\src\vga_render.v .\src\testbench_top.v
vvp -n .\build\wave.out