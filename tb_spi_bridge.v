`timescale 1ns/1ps

module tb_spi_bridge_comprehensive;

    reg clk;
    reg rst_n;
    reg sclk;
    reg cs_n;
    reg mosi;
    wire miso;
    wire byte_sync;
    wire [7:0] data_in;
    reg  [7:0] data_out;
    reg [7:0] miso_captured_byte;

    // Test statistics
    integer test_count;
    integer pass_count;
    integer fail_count;

    // Capture byte_sync pulse
    reg byte_sync_detected;
    reg [7:0] data_in_captured;

    spi_bridge dut (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial clk = 0;
    always #50 clk = ~clk;

    always @(posedge clk) begin
        if (byte_sync) begin
            byte_sync_detected <= 1;
            data_in_captured <= data_in;
        end
    end

    task send_spi_byte;
        input [7:0] byte_to_send;
        input start_cs;
        input end_cs;
        integer i;
        begin
            if (start_cs) begin
                cs_n = 0;
                #1000;
            end

            miso_captured_byte = 0;

            for (i = 7; i >= 0; i = i - 1) begin
                mosi = byte_to_send[i];
                #1000;

                sclk = 1;
                #500;
                miso_captured_byte[i] = miso;
                #500;

                sclk = 0;
                #1000;
            end

            if (end_cs) begin
                #1000;
                cs_n = 1;
                mosi = 0;
                #1000;
            end
        end
    endtask

    task abort_transfer;
        input [7:0] byte_to_send;
        input integer abort_at_bit;
        integer i;
        begin
            cs_n = 0;
            #1000;

            for (i = 7; i >= 0; i = i - 1) begin
                mosi = byte_to_send[i];
                #1000;
                sclk = 1;
                #1000;
                sclk = 0;
                #1000;

                if (i == abort_at_bit) begin
                    cs_n = 1;
                    mosi = 0;
                    #2000;
                    i = -1;
                end
            end
        end
    endtask

    task wait_for_byte_sync;
        integer timeout;
        begin
            timeout = 0;
            while (!byte_sync_detected && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 1000)
                $display(" [FAIL] Timeout waiting for byte_sync");
        end
    endtask

    task check_result;
        input [7:0] expected_mosi;
        input [7:0] expected_miso;
        input check_mosi;
        input check_miso;
        input [255:0] test_name;
        begin
            test_count = test_count + 1;

            if (check_mosi) begin
                if (data_in_captured == expected_mosi && byte_sync_detected) begin
                    $display(" [PASS] %0s: MOSI 0x%h", test_name, expected_mosi);
                    pass_count = pass_count + 1;
                end else begin
                    $display(
                      " [FAIL] %0s: MOSI expected 0x%h, got 0x%h (sync=%0d)",
                      test_name,
                      expected_mosi,
                      data_in_captured,
                      byte_sync_detected
                    );
                    fail_count = fail_count + 1;
                end
            end

            if (check_miso) begin
                if (miso_captured_byte == expected_miso) begin
                    $display(" [PASS] %0s: MISO 0x%h", test_name, expected_miso);
                    pass_count = pass_count + 1;
                end else begin
                    $display(
                      " [FAIL] %0s: MISO expected 0x%h, got 0x%h",
                      test_name,
                      expected_miso,
                      miso_captured_byte
                    );
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_spi_bridge_comprehensive);

        rst_n = 0;
        sclk = 0;
        cs_n = 1;
        mosi = 0;
        data_out = 0;
        byte_sync_detected = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        #50 rst_n = 1;
        #100;

        $display("========================================");
        $display("=== COMPREHENSIVE SPI BRIDGE TESTS ===");
        $display("========================================");

        // TEST 1: All zeros
        $display("\n--- Test 1: All zeros ---");
        byte_sync_detected = 0;
        data_out = 8'h00;
        send_spi_byte(8'h00, 1, 1);
        wait_for_byte_sync();
        check_result(8'h00, 8'h00, 1, 1, "All zeros");
        #200;

        // TEST 2: All ones
        $display("\n--- Test 2: All ones ---");
        byte_sync_detected = 0;
        data_out = 8'hFF;
        send_spi_byte(8'hFF, 1, 1);
        wait_for_byte_sync();
        check_result(8'hFF, 8'hFF, 1, 1, "All ones");
        #200;

        // TEST 3: Pattern 0xAA
        $display("\n--- Test 3: Pattern 0xAA ---");
        byte_sync_detected = 0;
        data_out = 8'hAA;
        send_spi_byte(8'hAA, 1, 1);
        wait_for_byte_sync();
        check_result(8'hAA, 8'hAA, 1, 1, "Pattern 0xAA");
        #200;

        // TEST 4: Pattern 0x55
        $display("\n--- Test 4: Pattern 0x55 ---");
        byte_sync_detected = 0;
        data_out = 8'h55;
        send_spi_byte(8'h55, 1, 1);
        wait_for_byte_sync();
        check_result(8'h55, 8'h55, 1, 1, "Pattern 0x55");
        #200;

        // TEST 5: Walking 1s
        $display("\n--- Test 5: Walking 1s ---");
        byte_sync_detected = 0;
        data_out = 8'h01;
        send_spi_byte(8'h80, 1, 1);
        wait_for_byte_sync();
        check_result(8'h80, 8'h01, 1, 1, "Walking 1s");
        #200;

        // TEST 6: Full duplex
        $display("\n--- Test 6: Full duplex (TX:0xF0 RX:0x0F) ---");
        byte_sync_detected = 0;
        data_out = 8'hF0;
        send_spi_byte(8'h0F, 1, 1);
        wait_for_byte_sync();
        check_result(8'h0F, 8'hF0, 1, 1, "Full duplex");
        #200;

        // TEST 7: Back-to-back transfers
        $display("\n--- Test 7: Back-to-back transfers ---");
        byte_sync_detected = 0;
        data_out = 8'hDE;
        send_spi_byte(8'hAB, 1, 0);
        wait_for_byte_sync();
        check_result(8'hAB, 8'hDE, 1, 1, "First byte");

        byte_sync_detected = 0;
        data_out = 8'hEF;
        send_spi_byte(8'hCD, 0, 1);
        wait_for_byte_sync();
        check_result(8'hCD, 8'hEF, 1, 1, "Second byte");
        #200;

        // TEST 8: Three consecutive bytes
        $display("\n--- Test 8: Three consecutive bytes ---");
        byte_sync_detected = 0;
        data_out = 8'h11;
        send_spi_byte(8'hAA, 1, 0);
        wait_for_byte_sync();
        check_result(8'hAA, 8'h11, 1, 1, "Byte 1/3");

        byte_sync_detected = 0;
        data_out = 8'h22;
        send_spi_byte(8'hBB, 0, 0);
        wait_for_byte_sync();
        check_result(8'hBB, 8'h22, 1, 1, "Byte 2/3");

        byte_sync_detected = 0;
        data_out = 8'h33;
        send_spi_byte(8'hCC, 0, 1);
        wait_for_byte_sync();
        check_result(8'hCC, 8'h33, 1, 1, "Byte 3/3");
        #200;

        // TEST 9: CS abort
        $display("\n--- Test 9: CS abort at bit 4 ---");
        byte_sync_detected = 0;
        data_out = 8'h99;
        abort_transfer(8'hAB, 4);
        #200;
        if (!byte_sync_detected) begin
            $display(" [PASS] CS abort: No byte_sync");
            test_count = test_count + 1;
            pass_count = pass_count + 1;
        end else begin
            $display(" [FAIL] CS abort: Unexpected byte_sync");
            test_count = test_count + 1;
            fail_count = fail_count + 1;
        end
        #200;

        // TEST 10: byte_sync pulse width
        $display("\n--- Test 10: byte_sync pulse width ---");
        byte_sync_detected = 0;
        data_out = 8'h77;
        send_spi_byte(8'h88, 1, 1);
        wait_for_byte_sync();
        #20;
        if (!byte_sync) begin
            $display(" [PASS] byte_sync is single-cycle");
            test_count = test_count + 1;
            pass_count = pass_count + 1;
        end else begin
            $display(" [FAIL] byte_sync stuck high");
            test_count = test_count + 1;
            fail_count = fail_count + 1;
        end
        #200;

        // TEST 11: Reset during transfer
        $display("\n--- Test 11: Reset during transfer ---");
        byte_sync_detected = 0;
        data_out = 8'h12;
        cs_n = 0;
        #1000;

        mosi = 1; #1000; sclk = 1; #1000; sclk = 0; #1000;
        mosi = 0; #1000; sclk = 1; #1000; sclk = 0; #1000;

        rst_n = 0;
        #500;
        rst_n = 1;
        #2000;

        cs_n = 1;
        if (!byte_sync_detected) begin
            $display(" [PASS] Reset: No spurious byte_sync");
            test_count = test_count + 1;
            pass_count = pass_count + 1;
        end else begin
            $display(" [FAIL] Reset: Unexpected byte_sync");
            test_count = test_count + 1;
            fail_count = fail_count + 1;
        end
        #200;

        // TEST 12: Minimal CS gap
        $display("\n--- Test 12: Minimal CS gap ---");
        byte_sync_detected = 0;
        data_out = 8'h42;
        send_spi_byte(8'h24, 1, 1);
        wait_for_byte_sync();
        check_result(8'h24, 8'h42, 1, 1, "Before gap");

        #20;

        byte_sync_detected = 0;
        data_out = 8'h66;
        send_spi_byte(8'h99, 1, 1);
        wait_for_byte_sync();
        check_result(8'h99, 8'h66, 1, 1, "After gap");
        #200;

        $display("\n========================================");
        $display("=== TEST SUMMARY ===");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 test_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("=== ALL TESTS PASSED ===");
        else
            $display("=== %0d TESTS FAILED ===", fail_count);
        $display("========================================");

        $finish;
    end

endmodule
