
`include "ws2812b.sv"
`include "controller.sv"
`include "rules.sv"

module top(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT,
    output logic    _48b,
    output logic    LED,        // Debugging
    output logic    RGB_R       // Debugging
);

// signals //
// rules
    logic [63:0] grid;
    logic [63:0] initial_pattern;
    logic step_game;
    logic reset;

// output driver and controller
    logic [23:0] shift_reg = 24'd0;
    logic shift;
    logic ws2812b_out;
    logic [5:0] pixel;
    logic load_sreg;
    logic transmit_pixel;

//define starting pattern in hex, 64 bit (easy to convert to binary for grid display)
    localparam logic [63:0] GLIDER = 64'h4020E00000000000;

// set colors in GRB order (based on video explanation?)
    localparam [23:0] OFF     = 24'h000000;
    localparam [23:0] RED     = 24'h00FF00;
    localparam [23:0] GREEN   = 24'hFF0000;
    localparam [23:0] BLUE    = 24'h0000FF;

//assign
    assign initial_pattern = GLIDER;
    assign reset = SW;

// instances //
// instance rules
    rules u3 (
        .clk(clk),
        .reset(reset),
        .step(step_game),
        .initial_pattern(initial_pattern),
        .grid(grid) //get next grid step here
    );

// Instance the WS2812B output driver
    ws2812b u4 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

// Instance the controller
    controller u5 (
        .clk            (clk), 
        .load_sreg      (load_sreg), 
        .transmit_pixel (transmit_pixel), 
        .pixel          (pixel), 
        .game_step      (step_game)
    );

// Shift Reg pixel color depending on state
    always_ff @(posedge clk) begin

        if (load_sreg) begin
            // conditional true false statement
            shift_reg <= grid[pixel] ? RED : OFF;
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    assign _48b = ws2812b_out;

endmodule
