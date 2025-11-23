`timescale 1ns/1ps

module tb_counter;

    // ============================
    // DUT Inputs
    // ============================
    reg clk;
    reg rst_n;
    reg en;
    reg upnotdown;
    reg count_reset;
    reg [7:0] prescale;
    reg [15:0] period;

    // DUT Output
    wire [15:0] count_val;

    // ============================
    // Instantiate DUT
    // ============================
    counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .count_val(count_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale)
    );

    // ============================
    // Clock
    // ============================
    initial clk = 0;
    always #5 clk = ~clk;

    // ============================
    // HELPER TASKS (IVerilog-safe)
    // ============================

    task step;
        input integer n;
        integer i;
        begin
            for (i=0; i<n; i=i+1)
                @(posedge clk);
        end
    endtask

    task assert_equal;
        input [15:0] got;
        input [15:0] expected;
        begin
            if (got !== expected) begin
                $display("❌ ASSERT FAILED at t=%0t : got %0d expected %0d",
                        $time, got, expected);
                $finish;
            end
        end
    endtask

    task show;
        begin
            $display("[%0t] CNT=%0d  en=%b  up=%b  pres=%0d  per=%0d",
                    $time, count_val, en, upnotdown, prescale, period);
        end
    endtask

    // ============================
    // BEGIN TESTS
    // ============================
    integer i;
    integer cycles_before;
    integer cycle_cnt;

    initial begin
        $dumpfile("counter_full_tb.vcd");
        $dumpvars(0, tb_counter);

        // default
        rst_n = 0;
        en = 0;
        upnotdown = 1;
        count_reset = 0;
        prescale = 0;
        period = 10;

        step(3);
        rst_n = 1;
        step(1);

        // ===========================================================
        // TEST 1 — RESET
        // ===========================================================
        $display("\n=== TEST 1 — RESET ===");
        assert_equal(count_val, 0);

        // ===========================================================
        // TEST 2 — SIMPLE UP COUNT
        // ===========================================================
        $display("\n=== TEST 2 — SIMPLE COUNT UP ===");
        en = 1;
        upnotdown = 1;
        prescale = 0;

        while (count_val != period)
            step(1);

        step(1);
        assert_equal(count_val, 0);

        // ===========================================================
        // TEST 3 — COUNT DOWN
        // ===========================================================
        $display("\n=== TEST 3 — COUNT DOWN ===");
        upnotdown = 0;

        step(1);
        assert_equal(count_val, period);

        while (count_val != 0)
            step(1);

        step(1);
        assert_equal(count_val, period);

        // ===========================================================
        // TEST 4 — PRESCALE
        // ===========================================================
        $display("\n=== TEST 4 — PRESCALE ===");
        prescale = 5;
        count_reset = 1; step(1); count_reset = 0;

        cycles_before = count_val;
        cycle_cnt = 0;

        while (count_val == cycles_before) begin
            step(1);
            cycle_cnt = cycle_cnt + 1;
        end

        assert_equal(cycle_cnt, prescale + 1);

       // ===========================================================
// TEST 5 — FREEZE (en=0)
// ===========================================================
$display("\n=== TEST 5 — FREEZE (en=0) ===");

// 1) Reset complet pentru stare stabilă
rst_n = 0; step(1);
rst_n = 1; step(2);

// 2) Setări de test
prescale    = 5;
period      = 10;
upnotdown   = 1;
en          = 1;

// 3) Las counterul să avanseze puțin
step(20);

// 4) Salvez valoarea înainte de înghețare
cycles_before = count_val;

// 5) Dezactivez counterul (FREEZE)
en = 0;

// 6) Aștept MULT → trebuie să rămână înghețat
step(30);
assert_equal(count_val, cycles_before);

// 7) Repornește counterul
en = 1;

// 8) Așteaptă suficient cât să termine prescalerul
step(prescale + 2);

// 9) Verificare logică
if (cycles_before == period)
    assert_equal(count_val, 0);
else
    assert_equal(count_val, cycles_before + 1);

        // ===========================================================
        // TEST 6 — COUNT_RESET
        // ===========================================================
        $display("\n=== TEST 6 — COUNT_RESET ===");
        count_reset = 1; step(1); count_reset = 0;
        assert_equal(count_val, 0);

        // ===========================================================
        // TEST 7 — CHANGE PERIOD MID-RUN
        // ===========================================================
        $display("\n=== TEST 7 — CHANGE PERIOD MID-RUN ===");
        period = 4;
        prescale = 0;
        upnotdown = 1;
        count_reset = 1; step(1); count_reset = 0;

        step(4);
        assert_equal(count_val, 4);

        step(1);
        assert_equal(count_val, 0);

        // ===========================================================
        // TEST 8 — DIRECTION FLIP MID RUN
        // ===========================================================
        $display("\n=== TEST 8 — DIRECTION FLIP ===");
        period = 10;
        count_reset = 1; step(1); count_reset = 0;
        prescale = 0;
        upnotdown = 1;

        step(1);
        cycles_before = count_val;

        upnotdown = 0;

        step(1);

        if (cycles_before == 0)
            assert_equal(count_val, period);
        else
            assert_equal(count_val, cycles_before - 1);

        // ===========================================================
        // TEST 9 — LARGE PRESCALE
        // ===========================================================
        $display("\n=== TEST 9 — LARGE PRESCALE ===");
        prescale = 20;
        count_reset = 1; step(1); count_reset = 0;

        cycles_before = count_val;
        cycle_cnt = 0;

        while (count_val == cycles_before) begin
            step(1);
            cycle_cnt = cycle_cnt + 1;
        end

        assert_equal(cycle_cnt, prescale + 1);

        // ===========================================================
        // TEST 10 — PERIOD = 0
        // ===========================================================
        $display("\n=== TEST 10 — PERIOD = 0 EDGE CASE ===");
        period = 0;
        prescale = 0;
        upnotdown = 1;

        count_reset = 1; step(1); count_reset = 0;

        step(20);
        assert_equal(count_val, 0);

        // ===========================================================
        // TEST 11 — RANDOM STRESS TEST
        // ===========================================================
        $display("\n=== TEST 11 — RANDOM STRESS TEST ===");

        period = 20;
        prescale = 0;
        upnotdown = 1;
        count_reset = 1; step(1); count_reset = 0;

        for (i=0; i<200; i=i+1) begin
            step($urandom_range(1,4));

            if ($urandom % 7 == 0)
                period = $urandom_range(0,20);

            if ($urandom % 11 == 0)
                upnotdown = ~upnotdown;

            if ($urandom % 13 == 0)
                prescale = $urandom_range(0,10);

            if ($urandom % 17 == 0)
                en = ~en;

            if ($urandom % 19 == 0) begin
                count_reset = 1; step(1); count_reset = 0;
            end
        end

        $display("\n==============================================");
        $display("         ALL COUNTER TESTS PASSED");
        $display("==============================================\n");

        $finish;
    end

endmodule
