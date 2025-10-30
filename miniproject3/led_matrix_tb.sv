`timescale 10ns/10ns
`include "top.sv"

// displays test in terminal in the form:
// Frame (frame number): grid = (grid values in hex code)

//note: the grid display from the simulation is reversed and expanded
//      from 1 to 2 bits for each index when comparing to the format
//      of my initial pattern.

module led_matrix_tb;

    logic clk = 0;
    logic SW;
    logic BOOT = 1'b1;

    top u0 (
        .clk            (clk), 
        .SW             (SW), 
        .BOOT           (BOOT)
    );

    initial begin
        //start by pressing switch
        SW = 1'b0;
        repeat (20) @(posedge clk);  // Hold reset for 20 clocks
        
        // release switch
        SW = 1'b1;
        
        // show grid each frame in hexcode
        repeat (5) begin // first 5 frames
            @(posedge u0.step_game);
            $display("Frame %0d: grid = %h", u0.frame, u0.grid);
        end      
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule