`timescale 1ns/1ps

module tb_pwm_gen;

    reg clk;
    reg rst_n;

    reg pwm_en;
    reg [15:0] period;
    reg [7:0] functions;
    reg [15:0] compare1;
    reg [15:0] compare2;
    reg [15:0] count_val;

    wire pwm_out;

    // DUT
    pwm_gen uut (
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

    // clock (100ns = 10MHz)
    always #50 clk = ~clk;

    // TASKURI -----------------------------------------------------

    task check(input [127:0] name, input cond);
        begin
            if (cond)
                $display("  ✓ %0s", name);
            else begin
                $display("  ✗ %0s", name);
                $stop;
            end
        end
    endtask

    // înaintează count_val pe un ciclu
    task step_to(input [15:0] next_val);
        begin
            count_val = next_val;
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------
    // TEST SUITE
    // -------------------------------------------------------------
    initial begin
        clk = 0;
        rst_n = 0;

        pwm_en = 0;
        period = 16'd8;
        functions = 8'h00;
        compare1 = 16'd3;
        compare2 = 16'd6;
        count_val = 16'd0;

        #20 rst_n = 1;

        $display("\n=== TEST 1: PWM dezactivat ===");
        pwm_en = 0;
        step_to(0);
        check("pwm_out rămâne 0", pwm_out == 0);
        step_to(3);
        check("pwm_out rămâne 0", pwm_out == 0);

        $display("\n=== TEST 2: LEFT ALIGNED (functions = 00) ===");
        functions = 8'b0000_0000;  // aligned, left
        pwm_en = 1;
        step_to(0);
        check("Pornește pe 1 (left aligned)", pwm_out == 1);

        step_to(1);
        step_to(2);
        step_to(3);  // compare1
        check("Toggling la compare1 → devine 0", pwm_out == 0);

        // at overflow (count_val=0 again), revine la început
        step_to(8);
        step_to(0);
        check("Overflow → redevine 1", pwm_out == 1);

        $display("\n=== TEST 3: RIGHT ALIGNED (functions = 01) ===");
        functions = 8'b0000_0001; // aligned, right
        step_to(1);  // Avansează la o altă valoare
        step_to(0);  // Apoi revino la 0
        check("Pornește pe 0 (right aligned)", pwm_out == 0);

        step_to(3);
        check("Toggle la compare1 → devine 1", pwm_out == 1);

        step_to(8);
        step_to(0);
        check("Overflow → redevine 0", pwm_out == 0);

        $display("\n=== TEST 4: UNALIGNED (functions = 10) ===");
        functions = 8'b0000_0010; // unaligned mode
        compare1 = 3;
        compare2 = 6;

        step_to(1);  // Avansează la o altă valoare
        step_to(0);  // Apoi revino la 0
        check("Început nealiniat → 0", pwm_out == 0);

        step_to(1);
        step_to(2);
        step_to(3);
        check("La compare1 → devine 1", pwm_out == 1);

        step_to(4);
        step_to(5);
        step_to(6);
        check("La compare2 → devine 0", pwm_out == 0);

        $display("\n=== TEST 5: UNALIGNED — întreg ciclu ===");
        // verificăm încă un ciclu
        step_to(7);
        step_to(8);
        step_to(0);
        check("(next cycle) începe din nou pe 0", pwm_out == 0);

        step_to(3);
        check("La compare1 → devine 1", pwm_out == 1);

        step_to(6);
        check("La compare2 → devine 0", pwm_out == 0);

        $display("\n=== TOATE TESTELE PWM AU TRECUT ✓ ===\n");

        $finish;
    end

endmodule
