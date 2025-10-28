// controller

module controller (
    input logic clk, 
    output logic load_sreg, 
    output logic transmit_pixel, 
    output logic [5:0] pixel, 
    output logic game_step
);

// define main phases in bits
    localparam TRANSMIT_FRAME = 1'b0;
    localparam IDLE           = 1'b1;

//define transmit sub phases in bits
    localparam [2:0] READ_CELL      = 3'b001;
    localparam [2:0] LOAD_SREG      = 3'b010;
    localparam [2:0] TRANSMIT_PIXEL = 3'b100;

// define cycle lengths
    localparam [8:0] TRANSMIT_CYCLES = 9'd360;       // = 24 bits / pixel x 15 cycles / bit
    localparam [19:0] IDLE_CYCLES    = 20'd351832;   // = 375000 - 64 x (360 + 2) for 32 frames / second

//initialize counters
    logic [5:0] pixel_counter    = 6'd0;
    logic [8:0] transmit_counter = 9'd0;
    logic [19:0] idle_counter    = 20'd0;

// initialize remaining variables //
//keep track when phases are done for next step
    logic transmit_pixel_done;
    logic idle_done;
// state tracking variables
    logic state = TRANSMIT_FRAME; //initial
    //logic next_state;
// transmit sub phase tracking variables
    logic [2:0] transmit_phase = READ_CELL; //initial
    logic [2:0] next_transmit_phase;

// define last cycle as one before the end
    assign transmit_pixel_done = (transmit_counter == TRANSMIT_CYCLES - 1);
    assign idle_done = (idle_counter == IDLE_CYCLES - 1);

//state machine //
//switch to next state
    always_ff @(negedge clk) begin
        state <= next_state;
        transmit_phase <= next_transmit_phase;
    end

// update next state
    always_comb begin
            unique case (state)
                TRANSMIT_FRAME:
                    if ((pixel_counter == 6'd63) && (transmit_pixel_done))
                        next_state = IDLE;
                    else
                        next_state = TRANSMIT_FRAME;
                IDLE:
                    if (idle_done)
                        next_state = TRANSMIT_FRAME;
                    else
                        next_state = IDLE;
                default:
                    next_state = IDLE;
            endcase
        end

// go through transmit sub phases: read # of live neighbors (READ_CELL), load LED state (LOAD_SREG), transmit bits (TRANSMIT_PIXEL)
always_comb begin
    if (state == TRANSMIT_FRAME) begin
            case (transmit_phase)
                READ_CELL:
                    next_transmit_phase = LOAD_SREG;
                LOAD_SREG:
                    next_transmit_phase = TRANSMIT_PIXEL;
                TRANSMIT_PIXEL:
                    next_transmit_phase = transmit_pixel_done ? READ_CELL : TRANSMIT_PIXEL;
                default:
                    next_transmit_phase = READ_CELL;
            endcase
        end
        else begin
            next_transmit_phase = READ_CELL;
        end
end

// idle state counter timer
    always_ff @(negedge clk) begin
        if (state == IDLE) begin
            idle_counter <= idle_counter + 1;
        end
        else begin
            idle_counter <= 20'd0;
        end
    end

// transmit state counter timer
    always_ff @(negedge clk) begin
        if (transmit_phase == TRANSMIT_PIXEL) begin //check for last transmit phase
            transmit_counter <= transmit_counter + 1;
        end
        else begin
            transmit_counter <= 9'd0;
        end
    end

// select next pixel
    always_ff @(negedge clk) begin
        if ((state == TRANSMIT_FRAME) && transmit_pixel_done) begin //move on once transmit phase is done
            pixel_counter <= pixel_counter + 1;
        end
    end

// finish idle state, move to next game sequence
    assign pixel = pixel_counter;
    assign game_step = (state == IDLE && idle_done);

endmodule


