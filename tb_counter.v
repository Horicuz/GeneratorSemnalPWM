`timescale 1ns/1ps

module tb_counter;

    reg clk;
    reg rst_n;

    reg [15:0] period;
    reg en;
    reg count_reset;
    reg upnotdown;
    reg [7:0] prescale;

    wire [15:0] count_val;

    // DUT
    counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .count_val(count_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale)
    );

    // Clock 100ns = 10MHz
    always #50 clk = ~clk;

    // TASKURI ---------------------------------------------------

    task check(input [127:0] name, input cond);
        begin
            if(cond)
                $display("  ✓ %0s", name);
            else begin
                $display("  ✗ %0s", name);
                $stop;
            end
        end
    endtask

    task wait_cycles(input integer n);
        integer i;
        begin
            for(i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // TEST SUITE
    // ------------------------------------------------------------
    initial begin
        clk = 0;
        rst_n = 0;

        period = 16'd8;
        en = 0;
        count_reset = 0;
        upnotdown = 1;
        prescale = 0;

        $display("\n=== TEST 1: RESET ===");
        #20 rst_n = 1;
        wait_cycles(1);
        check("count_val=0 după reset", count_val == 0);

        $display("\n=== TEST 2: count_reset pulse ===");
        en = 1;
        prescale = 0;
        wait_cycles(3);
        count_reset = 1;
        wait_cycles(1);
        count_reset = 0;
        check("count_reset read 0 imediat după", count_val == 0);

        $display("\n=== TEST 3: EN = 0 (nu numără) ===");
        en = 0;
        wait_cycles(5);
        check("count_val rămâne 0", count_val == 0);

        $display("\n=== TEST 4: UP, prescale 0 (numără la fiecare clk) ===");
        en = 1;
        upnotdown = 1;  // UP
        prescale = 0;
        wait_cycles(4);
        check("count_val == 4", count_val == 4);

        $display("\n=== TEST 5: prescale=1 (numără la 2 clk) ===");
        prescale = 1;  // 1<<1 = 2 clk
        wait_cycles(4);
        // încă 4 cicluri => 2 incremente
        check("count_val == 6", count_val == 6);

        $display("\n=== TEST 6: prescale=2 (numără la 4 clk) ===");
        prescale = 2;  // 4 clk per increment
        wait_cycles(8);
        // încă 8 cicluri => 2 incremente
        check("count_val == 8", count_val == 8);

        $display("\n=== TEST 7: overflow UP ===");
        // suntem la 8 și period=8 => următorul increment revine la 0
        wait_cycles(4);  // încă un increment
        check("overflow → revine la 0", count_val == 0);

        $display("\n=== TEST 8: DOWN counting ===");
        upnotdown = 0;   // DOWN
        wait_cycles(4);  // un decrement
        check("count_val devine PERIOD (8)", count_val == 8);
        wait_cycles(4);  // încă un decrement
        check("count_val devine 7", count_val == 7);

        $display("\n=== TEST 9: DOWN wrap-around ===");
        // mergem până la 0
        while(count_val != 0)
            wait_cycles(4);
        wait_cycles(4);  // ar trebui să sară la PERIOD
        check("0 -> PERIOD", count_val == period);

        $display("\n=== TOATE TESTELE AU TRECUT ✓ ===\n");
        $finish;
    end

endmodule
