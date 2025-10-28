//apply game rules to current state to get next state

module rules (
    input logic clk,
    input logic reset,
    input logic step,           // pulse to advance to next turn
    input logic [63:0] initial_pattern,
    output logic [63:0] grid    //current state
);
    logic [63:0] next_grid;

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
    function automatic int neighbors(input int row, input int col, input logic [63:0] g);
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

                        if (g[idx]) living++; // returns true if neighbor is alive
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

                if (grid[index]) begin //grid[index] is selected cell is alive
                    //cell continues to live if it has 2 or 3 living neighbors
                    next_grid[index] = (living_neighbors == 2 || living_neighbors==3);
                end
                else begin // if selected cell is dead
                    //cell becomes alive if it has 3 neighbors
                    next_grid[index] = (living_neighbors == 3);
                end
            end
        end
    end
endgenerate

endmodule