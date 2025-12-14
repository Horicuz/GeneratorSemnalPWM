`timescale 1ns/1ps

module tb_regs;

    reg clk;
    reg rst_n;

    reg read;
    reg write;
    reg [5:0] addr;
    reg [7:0] data_write;
    wire [7:0] data_read;

    reg [15:0] counter_val;

    wire [15:0] period;
    wire en;
    wire count_reset;
    wire upnotdown;
    wire [7:0] prescale;
    wire pwm_en;
    wire [7:0] functions;
    wire [15:0] compare1;
    wire [15:0] compare2;

    reg [7:0] tmp;

    regs uut (
        .clk(clk),
        .rst_n(rst_n),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write),
        .counter_val(counter_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale),
        .pwm_en(pwm_en),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2)
    );

    always #50 clk = ~clk;

    task write_reg(input [5:0] a, input [7:0] d);
        begin
            @(posedge clk);
            #1;                 // Small delay after clock edge
            addr = a;
            data_write = d;
            write = 1'b1;
            read = 1'b0;
            @(posedge clk);
            #1;                 // Small delay after clock edge
            write = 1'b0;
        end
    endtask

    task read_reg(input [5:0] a, output [7:0] val);
        begin
            @(posedge clk);
            addr = a;
            read = 1'b1;
            write = 1'b0;
            @(posedge clk);
            val = data_read;
            read = 1'b0;
        end
    endtask

    task check(input [127:0] name, input cond);
        begin
            if (cond)
                $display(" ✓ %0s", name);
            else begin
                $display(" ✗ %0s", name);
                $stop;
            end
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        read = 0;
        write = 0;
        addr = 0;
        data_write = 0;
        counter_val = 16'hABCD;

        #20;
        rst_n = 1;
        #20;

        $display("\n=== TEST 1: Reset values ===");
        check("period=0", period == 16'h0000);
        check("compare1=0", compare1 == 16'h0000);
        check("compare2=0", compare2 == 16'h0000);
        check("en=0", en == 1'b0);
        check("upnotdown=0", upnotdown == 1'b0);
        check("prescale=0", prescale == 8'h00);
        check("pwm_en=0", pwm_en == 1'b0);
        check("functions=0", functions == 8'h00);

        $display("\n=== TEST 2: Write + read PERIOD ===");
        write_reg(6'h00, 8'h34);
        write_reg(6'h01, 8'h12);
        #1;
        check("period = 0x1234", period == 16'h1234);

        read_reg(6'h00, tmp); check("READ period LSB", tmp == 8'h34);
        read_reg(6'h01, tmp); check("READ period MSB", tmp == 8'h12);

        $display("\n=== TEST 3: Write + read COMPARE1 ===");
        write_reg(6'h03, 8'hAA);
        write_reg(6'h04, 8'h55);
        check("compare1=0x55AA", compare1 == 16'h55AA);

        $display("\n=== TEST 4: Write + read COMPARE2 ===");
        write_reg(6'h05, 8'hCC);
        write_reg(6'h06, 8'h77);
        check("compare2=0x77CC", compare2 == 16'h77CC);

        $display("\n=== TEST 5: Counter enable ===");
        write_reg(6'h02, 8'h01);
        check("en=1", en == 1);

        $display("\n=== TEST 6: upnotdown ===");
        write_reg(6'h0B, 8'h01);
        check("upnotdown=1", upnotdown == 1);

        $display("\n=== TEST 7: prescale ===");
        write_reg(6'h0A, 8'h3C);
        check("prescale=0x3C", prescale == 8'h3C);

        $display("\n=== TEST 8: pwm_en ===");
        write_reg(6'h0C, 8'h01);
        check("pwm_en=1", pwm_en == 1);

        $display("\n=== TEST 9: functions ===");
        write_reg(6'h0D, 8'b1010_1010);
        check("functions=0xAA", functions == 8'hAA);

        $display("\n=== TEST 10: COUNTER_VAL read-only ===");
        read_reg(6'h08, tmp); check("LSB correct", tmp == 8'hCD);
        read_reg(6'h09, tmp); check("MSB correct", tmp == 8'hAB);

        $display("\n=== TEST 11: COUNTER_RESET pulse ===");
        write_reg(6'h07, 8'hFF);

        #1 check("RESET pulse=1", count_reset == 1);

        @(posedge clk);
        #1 check("RESET auto-cleared=0", count_reset == 0);

        $display("\n=== TEST 12: Invalid read ===");
        read_reg(6'h3F, tmp);
        check("Invalid returns 0", tmp == 8'h00);

        $display("\nALL TESTS PASSED ✓\n");
        $finish;
    end

endmodule
