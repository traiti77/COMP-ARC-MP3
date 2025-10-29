//apply game rules to current state to get next state

module rules (
    input logic clk,
    input logic reset,
    input logic step,           // pulse to advance to next turn
    input logic [127:0] initial_pattern,
    output logic [127:0] grid   //current state
);
    logic [127:0] next_grid;

//start and reset to initial grid pattern, otherwise continue game sequence
    always_ff @(posedge clk) begin
        if (reset) begin
            grid <= initial_pattern;
        end
        else if (step) begin
            grid <= next_grid;
        end
    end

// count living neighbors knowing the row and collumn index and current grid layout 
    function automatic int neighbors(input int row, input int col, input logic [127:0] g);
        //set count to 0 initially
        int living;
        // define for neighbor indexing
        int r, c, nr, nc, idx;
        living = 0;

        // Check all 8 neighbors
            for (nr = -1; nr <= 1; nr++) begin //neighbor rows, left right
                for (nc = -1; nc <= 1; nc++) begin //neighbor collumns, up down
                    if (!(nr == 0 && nc == 0)) begin //skip; this is the cell itself not a neighbor
                        //wrap around
                        r = (row + nr + 8) % 8; //add 8 to wrap around when negative,
                        c = (col + nc + 8) % 8; //use modulo 8 to correct when not wrapping
                        idx = r * 8 + c; //define neighbor index number

                        if (g[2*idx +: 2] == 2'b11) living++; // returns true if neighbor is alive
                    end
                end
            end
        neighbors =  living; // return living neighbor count to know if the cell will live
    endfunction

//define next grid state with game rules
generate;
    genvar ir, ic;

    for (ir=0; ir<8; ir++) begin // index through each grid row
        for (ic=0; ic<8; ic++) begin // index through each grid column 
            localparam int index = ir * 8 + ic; //get selected cell index
            int living_neighbors;
            always_comb begin
                living_neighbors = neighbors(ir, ic, grid); 

                if (grid[2*index +: 2] == 2'b11) begin //grid[index] is selected cell is alive
                    //cell continues to live if it has 2 or 3 living neighbors
                    if (living_neighbors == 2 || living_neighbors==3) begin
                        next_grid[2*index +: 2] = 2'b11;
                    end
                    else begin
                        next_grid[2*index +: 2] = 2'b01;
                    end
                end
                else if (grid[2*index +: 2] == 2'b01) begin // selected cell is dead 1 cycle
                    //cell becomes alive if it has 3 neighbors
                    if (living_neighbors == 3) begin
                        next_grid[2*index +: 2] = 2'b11;
                    end
                    else begin
                        next_grid[2*index +: 2] = 2'b10;
                    end
                end
                else if (grid[2*index +: 2] == 2'b10) begin // selected cell is dead 2 cycles
                    //cell becomes alive if it has 3 neighbors
                    if (living_neighbors == 3) begin
                        next_grid[2*index +: 2] = 2'b11;
                    end
                    else begin
                        next_grid[2*index +: 2] = 2'b00;
                    end
                end
                else  begin // selected cell is dead 3+ cycles
                    //cell becomes alive if it has 3 neighbors
                    if (living_neighbors == 3) begin
                        next_grid[2*index +: 2] = 2'b11;
                    end
                    else begin
                        next_grid[2*index +: 2] = 2'b00;
                    end
                end
            end
        end
    end
endgenerate

endmodule