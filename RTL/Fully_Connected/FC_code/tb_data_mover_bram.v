`timescale 1ns / 1ps

`define CNT_BIT 31
`define ADDR_WIDTH 12
`define DATA_WIDTH 32
`define MEM_DEPTH 4096
`define IN_DATA_WIDTH 8
`define NUM_CORE 4

module tb_data_mover_bram();
    reg                     clk, reset_n;
    reg                     start_run_i;
    reg [`CNT_BIT - 1 : 0]  run_count_i;
    wire                    idle_o;
    wire                    write_o;
    wire                    read_o;
    wire                    done_o;

    /* Memory IF BRAM0 */
    // No Write
    wire [`ADDR_WIDTH - 1 : 0]  addr0_b0;
    wire                        ce0_b0;
    wire                        we0_b0;
    wire [`DATA_WIDTH - 1 : 0]  q0_b0;
    wire [`DATA_WIDTH - 1 : 0]  d0_b0;

    /* Memory IF BRAM1 */
    // No Write
    wire [`ADDR_WIDTH - 1 : 0]  addr0_b1;
    wire                        ce0_b1;
    wire                        we0_b1;
    wire [`DATA_WIDTH - 1 : 0]  q0_b1;
    wire [`DATA_WIDTH - 1 : 0]  d0_b1;

    reg [`IN_DATA_WIDTH - 1 : 0] a_0;
    reg [`IN_DATA_WIDTH - 1 : 0] a_1;
    reg [`IN_DATA_WIDTH - 1 : 0] a_2;
    reg [`IN_DATA_WIDTH - 1 : 0] a_3;

    wire [`DATA_WIDTH - 1 : 0]  result_0;
    wire [`DATA_WIDTH - 1 : 0]  result_1;
    wire [`DATA_WIDTH - 1 : 0]  result_2;
    wire [`DATA_WIDTH - 1 : 0]  result_3;

    always begin
        #5 clk = ~clk;
    end

    integer i, f_in_node, f_in_weight, f_ot, status;

    initial begin
        // read file open, write file open
        f_in_node = $fopen("C:/FPGA_prj/URP/DATA_MOVER_BRAM/test_file/ref_c_rand_input_node.txt", "rb");
        f_in_weight = $fopen("C:/FPGA_prj/URP/DATA_MOVER_BRAM/test_file/ref_c_rand_input_weight.txt", "rb");
        f_ot = $fopen("C:/FPGA_prj/URP/DATA_MOVER_BRAM/test_file/ref_c_result.txt", "wb");
    end

    initial begin
        // initialize
        reset_n = 1;
        clk     = 0;
        start_run_i = 0;
        run_count_i = `MEM_DEPTH;

        // reset
        $display("Reset. [%0d]", $time);
        #100    reset_n = 0;
        #10     reset_n = 1;
        #10     @(posedge clk); #1

        // give BRAM to test data
        $display("Mem Write to BRAM0 [%0d]", $time);
        for(i = 0; i < run_count_i; i = i + 1) begin     
            status = $fscanf(f_in_node, "%d %d %d %d \n", a_0, a_1, a_2, a_3);
            BRAM0_inst.ram[i] = {a_0, a_1, a_2, a_3};
            status = $fscanf(f_in_weight, "%d %d %d %d \n", a_0, a_1, a_2, a_3);
            BRAM1_inst.ram[i] = {a_0, a_1, a_2, a_3};
        end

        // Check Idle
        $display("Check IDLE state [%0d]", $time);
        wait(idle_o);

        // start
        $display("Starting DATA_Mover_BRAM [%0d]", $time);
        start_run_i = 1;
        @(posedge clk); #1
        start_run_i = 0;
        
        // wait for done
        $display("Wait for done state [%0d]", $time);
        wait(done_o);

        $display("Read Result [%0d]", $time);
        $fwrite(f_ot, "%0d %0d %0d %0d ", result_0, result_1, result_2, result_3);

        $fclose(f_in_node);
        $fclose(f_in_weight);
        $fclose(f_ot);
        #100
        $display("Simulation Success.", $time);
        $finish;
    end

    // CALL DUT
    data_mover_bram 
    # (
        .CNT_BIT(`CNT_BIT),

        /* parameter for BRAM */
        .DWIDTH(`DATA_WIDTH),
        .AWIDTH(`ADDR_WIDTH),
        .MEM_SIZE(`MEM_DEPTH),
        .IN_DATA_WIDTH(`IN_DATA_WIDTH)
    ) data_mover_bram_inst (
        /* Special Inputs*/
        .clk(clk),
        .reset_n(reset_n),

        /* Signal From Register */
        .start_run_i(start_run_i), 
        .run_count_i(run_count_i), 

        /* Memory I/F for BRAM0 */
        .q_b0_i(q0_b0),

        /* Memory I/F for BRAM0 */
        .q_b1_i(q0_b1),

        /* State_Outputs */
        .idle_o(idle_o),
        .read_o(read_o),
        .write_o(write_o),
        .done_o(done_o),

        /* Memory I/F .for BRAM0 */
        .addr_b0_o(addr0_b0),
        .ce_b0_o(ce0_b0),
        .we_b0_o(we0_b0),
        .d_b0_o(d0_b0),
    
        /* Memory I/F .for BRAM1 */
        .addr_b1_o(addr0_b1),
        .ce_b1_o(ce0_b1),
        .we_b1_o(we0_b1),
        .d_b1_o(d0_b1),

        /* result for 4 Core */
        .result_0_o(result_0),
        .result_1_o(result_1),
        .result_2_o(result_2),
        .result_3_o(result_3)
    );

    true_dpbram
    #(
        .DWIDTH(`DATA_WIDTH),
        .AWIDTH(`ADDR_WIDTH),
        .MEM_SIZE(`MEM_DEPTH)
    ) BRAM0_inst (
        /* Special Inputs */
        .clk(clk),

        /* for port 0 */
        .addr0_i(addr0_b0),
        .ce0_i(ce0_b0),
        .we0_i(we0_b0),
        .d0_i(d0_b0),

        /* for port 1 */
        .addr1_i(),
        .ce1_i(),
        .we1_i(),
        .d1_i(),

        /* output for port 0 */
        .q0_o(q0_b0),
        
        /* output for port 1 */
        .q1_o()
    );

    true_dpbram
    #(
        .DWIDTH(`DATA_WIDTH),
        .AWIDTH(`ADDR_WIDTH),
        .MEM_SIZE(`MEM_DEPTH)
    ) BRAM1_inst (
        /* Special Inputs */
        .clk(clk),

        /* for port 0 */
        .addr0_i(addr0_b1),
        .ce0_i(ce0_b1),
        .we0_i(we0_b1),
        .d0_i(d0_b1),

        /* for port 1 */
        .addr1_i(),
        .ce1_i(),
        .we1_i(),
        .d1_i(),

        /* output for port 0 */
        .q0_o(q0_b1),
        
        /* output for port 1 */
        .q1_o()
    );
endmodule