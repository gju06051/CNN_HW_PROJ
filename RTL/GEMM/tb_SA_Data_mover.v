module tb_SA_Data_mover;
    parameter FIFO_DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 14;
    parameter PE_SIZE = 14;
    parameter integer MEM0_DEPTH = 896;
    parameter integer MEM1_DEPTH = 896;
    parameter integer MEM0_ADDR_WIDTH = 7;
    parameter integer MEM1_ADDR_WIDTH = 7;
    parameter integer MEM0_DATA_WIDTH = 112;
    parameter integer MEM1_DATA_WIDTH = 112;
    parameter integer OC = 64;

    reg clk;
    reg rst_n;
    reg  en;
    reg  [(FIFO_DATA_WIDTH*PE_SIZE)-1:0] rdata_i;
    wire [MEM0_DATA_WIDTH-1:0] mem0_d0;

    always #5 clk = ~clk;
    integer i;
    initial begin
        clk = 0;
        rst_n = 0;
        en = 0;
        rdata_i = 0;
        #50
            rst_n = 1'b1;
        #20
            for(i = 0; i < PE_SIZE+PE_SIZE-1; i = i +1) begin
                @(posedge clk);
                    #1;
                        if(i == 0) begin
                            en <= 1;
                            rdata_i <= {((FIFO_DATA_WIDTH*PE_SIZE)){1'b0}};
                        end
                        else if(i < PE_SIZE) begin
                            rdata_i <= (rdata_i >> 8) || {{i[FIFO_DATA_WIDTH-1:0]},{((FIFO_DATA_WIDTH*PE_SIZE)-FIFO_DATA_WIDTH){1'b0}}};
                        end else begin
                            rdata_i <= (rdata_i >> 8) || {{8'b0},{((FIFO_DATA_WIDTH*PE_SIZE)-FIFO_DATA_WIDTH){1'b0}}};
                        end
            end
    end


    SA_Data_mover # (
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .PE_SIZE(PE_SIZE),
    .MEM0_DEPTH(MEM0_DEPTH),
    .MEM1_DEPTH(MEM1_DEPTH),
    .MEM0_ADDR_WIDTH(MEM0_ADDR_WIDTH),
    .MEM1_ADDR_WIDTH(MEM1_ADDR_WIDTH),
    .MEM0_DATA_WIDTH(MEM0_DATA_WIDTH),
    .MEM1_DATA_WIDTH(MEM1_DATA_WIDTH),
    .OC(OC)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdata_i(rdata_i),
        .mem0_d0(mem0_d0)
    );

endmodule