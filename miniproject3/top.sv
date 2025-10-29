
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
    logic [127:0] grid;
    logic [127:0] initial_pattern;
    logic step_game;
    logic reset;

// output driver and controller
    logic [23:0] shift_reg = 24'd0;
    logic shift;
    logic ws2812b_out;
    logic [5:0] pixel;
    logic load_sreg;
    logic transmit_pixel;

    logic [4:0] frame;
    logic [4:0] last_frame;

// set colors in GRB order (based on video explanation?)
    localparam [23:0] OFF     = 24'h000000;
    localparam [23:0] RED     = 24'h00FF00;
    localparam [23:0] GREEN   = 24'hFF0000;
    localparam [23:0] BLUE    = 24'h0000FF;

//read mem file for initial pattern
// convert glider to 2 bit values to work with color change version
    logic [63:0] GLIDER [0:0];
    integer i;
    initial begin
        $readmemh("glider.txt", GLIDER);
        for (i = 0; i < 64; i++) begin
            initial_pattern[2*i +: 2] = GLIDER[0][63 - i] ? 2'b11 : 2'b00;
        end
    end
    assign reset = ~SW;

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
        .frame          (frame)
    );

    // Detect frame change to step in game
    always_ff @(posedge clk) begin
        last_frame <= frame;
    end
    assign step_game = (frame != last_frame); //change with frame


// Shift Reg pixel color depending on state
    always_ff @(posedge clk) begin

        if (load_sreg) begin
            // conditional true false statement
            if (grid[2*pixel +: 2] == 2'b11) begin //alive
                shift_reg <= GREEN;
            end
            else if (grid[2*pixel +: 2] == 2'b01) begin //dead 1st cycle
                shift_reg <= BLUE;
            end
            else if (grid[2*pixel +: 2] == 2'b10) begin //dead 2nd cycle
                shift_reg <= RED;
            end
            else begin // off
                shift_reg <= OFF;
            end
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    assign _48b = ws2812b_out;


endmodule
