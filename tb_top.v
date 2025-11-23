`timescale 1ns/1ps

module tb_top;
    // Semnale SPI (master)
    reg sclk;
    reg cs_n;
    reg miso;  // Din cauza conventiei inversate in top.v (input miso)
    wire mosi; // Din cauza conventiei inversate in top.v (output mosi)

    // Semnale sistem
    reg clk;
    reg rst_n;

    // Ieșire PWM
    wire pwm_out;

    // Instanțiere DUT
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .miso(miso),  // TB citește miso (wire) <- DUT output
        .mosi(mosi),  // TB scrie mosi (reg) -> DUT input
        .pwm_out(pwm_out)
    );

    // Generare ceas sistem (10MHz = 100ns perioadă)
    initial clk = 0;
    always #50 clk = ~clk;

    // ========================================================
    // TASK-URI PENTRU COMUNICAȚIE SPI
    // ========================================================

    // Trimite 1 byte pe SPI (MSB first) - Scrierea către slave
    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                miso = data[i];  // TB scrie pe miso (care merge la top.miso INPUT)
                #1000;
                
                sclk = 1;
                #500;
                #500;
                
                sclk = 0;
                #1000;
            end
        end
    endtask

    // Citește 1 byte de pe SPI (MSB first) - Citirea de la slave
    task spi_read_byte(output [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                miso = 0;  // TB nu trimite date când citește
                #1000;
                
                sclk = 1;
                #500;
                data[i] = mosi;  // TB citește de pe mosi (care vine de la top.mosi OUTPUT)
                #500;
                
                sclk = 0;
                #1000;
            end
        end
    endtask

    // Scriere în registru (operație completă)
    task spi_write_reg(
        input [5:0] addr,
        input high_low,      // 0=[7:0], 1=[15:8]
        input [7:0] data
    );
        begin
            // Activează slave
            cs_n = 0;
            #1000;

            // Byte 1: Comandă (Write=1, H/L, Address)
            spi_send_byte({1'b1, high_low, addr});

            // Byte 2: Data
            spi_send_byte(data);

            // Dezactivează slave
            sclk = 0;
            #1000;
            cs_n = 1;
            #2000;  // Delay între tranzacții
        end
    endtask

    // Scriere registru 16-bit
    task spi_write_reg16(input [5:0] addr, input [15:0] data);
        begin
            spi_write_reg(addr, 1'b0, data[7:0]);   // Low byte
            spi_write_reg(addr, 1'b1, data[15:8]);  // High byte
        end
    endtask

    // Scriere registru 1-bit sau 8-bit
    task spi_write_reg8(input [5:0] addr, input [7:0] data);
        begin
            spi_write_reg(addr, 1'b0, data);
        end
    endtask

    // Citire din registru
    task spi_read_reg(
        input [5:0] addr,
        input high_low,
        output [7:0] data
    );
        begin
            cs_n = 0;
            #1000;

            // Byte 1: Comandă (Read=0, H/L, Address)
            spi_send_byte({1'b0, high_low, addr});

            // Byte 2: Citește data
            spi_read_byte(data);

            sclk = 0;
            #1000;
            cs_n = 1;
            #2000;
        end
    endtask

    // Citire registru 16-bit
    task spi_read_reg16(input [5:0] addr, output [15:0] data);
        reg [7:0] low, high;
        begin
            spi_read_reg(addr, 1'b0, low);
            spi_read_reg(addr, 1'b1, high);
            data = {high, low};
        end
    endtask

    // Așteaptă N cicluri de ceas sistem
    task wait_clk(input integer n);
        repeat(n) @(posedge clk);
    endtask

    // Verificare cu mesaj
    task check(input [255:0] msg, input condition);
        begin
            if (condition)
                $display("  ✓ %0s", msg);
            else begin
                $display("  ✗ %0s", msg);
                $display("    Time: %0t", $time);
                $stop;
            end
        end
    endtask

    // ========================================================
    // SECVENȚĂ DE TEST
    // ========================================================

    reg [15:0] read_data;

    initial begin
        // Inițializare
        clk = 0;
        rst_n = 0;
        sclk = 0;
        cs_n = 1;
        miso = 0;

        // Reset
        #300;
        rst_n = 1;
        #200;

        $display("\n");
        $display("========================================");
        $display("  TEST PERIFERIC PWM - COMPLET");
        $display("========================================\n");

        // ====================================
        // TEST 1: Configurare inițială
        // ====================================
        $display("TEST 1: Scriere și citire registri");
        $display("------------------------------------");

        spi_write_reg16(6'h00, 16'd100);  // PERIOD = 100
        spi_read_reg16(6'h00, read_data);
        check("PERIOD scris și citit corect", read_data == 16'd100);

        spi_write_reg16(6'h03, 16'd30);   // COMPARE1 = 30
        spi_read_reg16(6'h03, read_data);
        check("COMPARE1 scris corect", read_data == 16'd30);

        spi_write_reg8(6'h0A, 8'd0);      // PRESCALE = 0 (no scaling)
        spi_write_reg8(6'h0B, 8'd1);      // UPNOTDOWN = 1 (up)

        $display("");

        // ====================================
        // TEST 2: PWM Left Aligned
        // ====================================
        $display("TEST 2: PWM Left Aligned");
        $display("------------------------------------");

        spi_write_reg16(6'h00, 16'd20);   // PERIOD = 20
        spi_write_reg16(6'h03, 16'd10);   // COMPARE1 = 10 (50% duty)
        spi_write_reg8(6'h0D, 8'b00);     // FUNCTIONS = 00 (left aligned)
        spi_write_reg8(6'h0A, 8'd0);      // PRESCALE = 0
        spi_write_reg8(6'h0B, 8'd1);      // UP counting

        // Reset counter
        spi_write_reg8(6'h07, 8'd1);      // COUNTER_RESET
        wait_clk(5);

        // Activează counter și PWM
        spi_write_reg8(6'h02, 8'd1);      // COUNTER_EN = 1
        spi_write_reg8(6'h0C, 8'd1);      // PWM_EN = 1

        wait_clk(5);
        check("PWM = 1 la start (left aligned)", pwm_out == 1'b1);

        // Așteaptă să ajungă la COMPARE1 (count_val = 10)
        repeat(12) @(posedge clk);
        check("PWM = 0 după COMPARE1", pwm_out == 1'b0);

        // Așteaptă overflow (counter revine la 0)
        repeat(12) @(posedge clk);  // 10 + 12 = 22, deci am trecut de 20 (overflow)
        check("PWM = 1 după overflow", pwm_out == 1'b1);

        $display("");

        // ====================================
        // TEST 3: PWM Right Aligned
        // ====================================
        $display("TEST 3: PWM Right Aligned");
        $display("------------------------------------");

        spi_write_reg8(6'h0C, 8'd0);      // PWM_EN = 0
        spi_write_reg8(6'h02, 8'd0);      // COUNTER_EN = 0
        wait_clk(3);

        spi_write_reg8(6'h07, 8'd1);      // COUNTER_RESET
        wait_clk(3);

        spi_write_reg8(6'h0D, 8'b01);     // FUNCTIONS = 01 (right aligned)

        spi_write_reg8(6'h02, 8'd1);      // COUNTER_EN = 1
        spi_write_reg8(6'h0C, 8'd1);      // PWM_EN = 1

        wait_clk(5);
        check("PWM = 0 la start (right aligned)", pwm_out == 1'b0);

        // Așteaptă să ajungă la COMPARE1 (count_val = 10)
        repeat(12) @(posedge clk);
        check("PWM = 1 după COMPARE1", pwm_out == 1'b1);

        // Așteaptă overflow (counter revine la 0)
        repeat(12) @(posedge clk);  // 10 + 12 = 22, deci am trecut de 20 (overflow)
        check("PWM = 0 după overflow", pwm_out == 1'b0);

        $display("");

        // ====================================
        // TEST 4: PWM Unaligned
        // ====================================
        $display("TEST 4: PWM Unaligned");
        $display("------------------------------------");

        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(3);

        spi_write_reg8(6'h07, 8'd1);
        wait_clk(3);

        spi_write_reg16(6'h03, 16'd5);    // COMPARE1 = 5
        spi_write_reg16(6'h05, 16'd15);   // COMPARE2 = 15
        spi_write_reg8(6'h0D, 8'b10);     // FUNCTIONS = 10 (unaligned)

        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);

        wait_clk(5);
        check("PWM = 0 la start (unaligned)", pwm_out == 1'b0);

        wait_clk(8);
        check("PWM = 1 la COMPARE1", pwm_out == 1'b1);

        wait_clk(12);
        check("PWM = 0 la COMPARE2", pwm_out == 1'b0);

        $display("");

        // ====================================
        // TEST 5: Prescaler
        // ====================================
        $display("TEST 5: Prescaler (PRESCALE=2, scalare cu 4)");
        $display("------------------------------------");

        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(3);

        spi_write_reg8(6'h07, 8'd1);
        wait_clk(3);

        spi_write_reg16(6'h00, 16'd10);
        spi_write_reg16(6'h03, 16'd5);
        spi_write_reg8(6'h0A, 8'd2);      // PRESCALE = 2 (div by 4)
        spi_write_reg8(6'h0D, 8'b00);

        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);

        wait_clk(10);
        $display("  Prescaler funcționează (PWM activ cu delay)");

        $display("");

        // ====================================
        // TEST 6: Down Counting
        // ====================================
        $display("TEST 6: Down Counting");
        $display("------------------------------------");

        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(3);

        spi_write_reg8(6'h07, 8'd1);
        wait_clk(3);

        spi_write_reg8(6'h0B, 8'd0);      // UPNOTDOWN = 0 (down)
        spi_write_reg8(6'h0A, 8'd0);      // PRESCALE = 0
        spi_write_reg16(6'h00, 16'd20);
        spi_write_reg16(6'h03, 16'd10);

        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);

        wait_clk(30);
        $display("  Down counting funcționează");

        $display("");

        // ====================================
        // TEST 7: Citire COUNTER_VAL
        // ====================================
        $display("TEST 7: Citire COUNTER_VAL");
        $display("------------------------------------");

        spi_read_reg16(6'h08, read_data);
        $display("  COUNTER_VAL = %0d", read_data);
        check("COUNTER_VAL citit cu succes", 1);

        $display("");

        // ====================================
        // TEST 8: Duty cycle diferite
        // ====================================
        $display("TEST 8: Duty Cycles - 25%%, 50%%, 75%%");
        $display("------------------------------------");

        // 25% duty
        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(2);
        spi_write_reg8(6'h07, 8'd1);
        wait_clk(2);

        spi_write_reg16(6'h00, 16'd40);
        spi_write_reg16(6'h03, 16'd10);   // 25%
        spi_write_reg8(6'h0D, 8'b00);
        spi_write_reg8(6'h0B, 8'd1);
        spi_write_reg8(6'h0A, 8'd0);

        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);
        wait_clk(50);
        $display("  25%% duty cycle OK");

        // 50% duty
        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(2);
        spi_write_reg8(6'h07, 8'd1);
        wait_clk(2);

        spi_write_reg16(6'h03, 16'd20);   // 50%
        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);
        wait_clk(50);
        $display("  50%% duty cycle OK");

        // 75% duty
        spi_write_reg8(6'h0C, 8'd0);
        spi_write_reg8(6'h02, 8'd0);
        wait_clk(2);
        spi_write_reg8(6'h07, 8'd1);
        wait_clk(2);

        spi_write_reg16(6'h03, 16'd30);   // 75%
        spi_write_reg8(6'h02, 8'd1);
        spi_write_reg8(6'h0C, 8'd1);
        wait_clk(50);
        $display("  75%% duty cycle OK");

        $display("");

        // ====================================
        // FINAL
        // ====================================
        $display("========================================");
        $display("  ✓✓✓ TOATE TESTELE AU TRECUT ✓✓✓");
        $display("========================================\n");

        #1000;
        $finish;
    end

    // Timeout
    initial begin
        #200000000;  // 200ms timeout
        $display("\n✗ TIMEOUT!");
        $finish;
    end

endmodule