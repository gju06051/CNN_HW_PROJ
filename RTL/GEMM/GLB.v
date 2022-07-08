    module GLB # (
        parameter FIFO_DATA_WIDTH = 8,
        parameter FIFO_DEPTH = 16,
        parameter PE_SIZE = 16
    )

    (
        input   clk,
        input   rst_n,
        input   wren_i,
        input   rden_i,

        output  [PE_SIZE-1:0] full_o,
        output  [PE_SIZE-1:0] empty_o,
        
        input   [FIFO_DATA_WIDTH*PE_SIZE-1:0] wdata_i,
        output  [FIFO_DATA_WIDTH*PE_SIZE-1:0] rdata_o
    );

    // rden_i_row = 
    reg rden_i_row [0:PE_SIZE-2];
    genvar k;
        generate
            for (k=0; k < PE_SIZE-2; k=k+1) begin 
                always @(posedge clk) begin
                   rden_i_row[k+1] <= rden_i_row[k];
                end
            end
        endgenerate

    always @(posedge clk) begin
        rden_i_row[0] <= rden_i;
    end

    wire w_rden_i_row [0:PE_SIZE-1];
    
    genvar i;
        generate
            for (i=1; i < PE_SIZE; i=i+1) begin 
                assign w_rden_i_row[i] = rden_i_row[i-1]; 
            end
        endgenerate
    assign w_rden_i_row[0] = rden_i;


    genvar j;
        generate
            for (j=0; j < PE_SIZE; j=j+1) begin : Buffer
                    FIFO #(
                        .DATA_WIDTH(FIFO_DATA_WIDTH),
                        .FIFO_DEPTH(FIFO_DEPTH)
                    ) FIFO_INST (   
                        // special signal
                        .clk            (clk), 
                        .rst_n          (rst_n), 
                        // primitives(input) 2D array, var[vector_idx][bit_idx]
                        .wren_i         (wren_i), 
                        .rden_i         (rden_i[j]),  
                        // enable signal(input) 2D array, var[vector_idx][bit_idx]
                        .full_o         (full_o[j]), 
                        .empty_o        (empty_o[j]), 
                        // primitives(output) 2D array, var[vector_idx][bit_idx]
                        .wdata_i        (wdata_i[FIFO_DATA_WIDTH*(PE_SIZE-1-j) +: FIFO_DATA_WIDTH]), 
                        .rdata_o        (rdata_o[FIFO_DATA_WIDTH*(PE_SIZE-1-j) +: FIFO_DATA_WIDTH])
                    );
            end
        endgenerate
    endmodule