`timescale 1ns/1ps

module tb_pwm_gen;

    reg clk;
    reg rst_n;

    reg pwm_en;
    reg [15:0] period;
    reg [7:0]  functions;
    reg [15:0] compare1;
    reg [15:0] compare2;
    reg [15:0] count_val;

    wire pwm_out;

    // Instantiere DUT
    pwm_gen dut (
        .clk(clk),
        .rst_n(rst_n),
        .pwm_en(pwm_en),
        .period(period),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2),
        .count_val(count_val),
        .pwm_out(pwm_out)
    );

    // Clock 10ns
    always #5 clk = ~clk;

    // Simulare counter simplificat pentru test
    task run_counter(input integer cycles);
        integer i;
        begin
            for (i=0; i<cycles; i=i+1) begin
                @(posedge clk);
                count_val <= (count_val == period) ? 0 : count_val + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("pwm_gen.vcd");
        $dumpvars(0, tb_pwm_gen);

        clk = 0;
        rst_n = 0;
        pwm_en = 0;
        period = 10;
        functions = 0;
        compare1 = 3;
        compare2 = 7;
        count_val = 0;

        repeat(3) @(posedge clk);
        rst_n = 1;

        // ================================================================
        // TEST 1 — PWM ALINIAT STÂNGA
        // ================================================================
        $display("\n[TEST 1] PWM Aliniat Stanga");

        functions = 8'b0000_0000; // unaligned=0, align_lr=0 (stânga)
        pwm_en = 1;

        run_counter(40);

        // ================================================================
        // TEST 2 — PWM ALINIAT DREAPTA
        // ================================================================
        $display("\n[TEST 2] PWM Aliniat Dreapta");

        functions = 8'b0000_0001; // unaligned=0, align_lr=1 (dreapta)
        count_val = 0;

        run_counter(40);

        // ================================================================
        // TEST 3 — PWM NEALINIAT
        // ================================================================
        $display("\n[TEST 3] PWM Nealiniat");

        functions = 8'b0000_0010; // unaligned=1
        count_val = 0;

        run_counter(40);

        $display("\n=== SIMULARE TERMINATĂ ===\n");
        $finish;
    end

endmodule
