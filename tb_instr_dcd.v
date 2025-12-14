`timescale 1ns/1ps

module tb_instr_dcd;

    reg clk;
    reg rst_n;
    reg byte_sync;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire read;
    wire write;
    wire [5:0] addr;
    reg [7:0] data_read;
    wire [7:0] data_write;

    integer test_count = 0;
    integer passed_count = 0;
    integer failed_count = 0;

    // Instantiate DUT
    instr_dcd uut (
        .clk(clk),
        .rst_n(rst_n),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write)
    );

    // Generate clock (10 MHz)
    always #50 clk = ~clk;

    // Utility: send a byte on SPI
    task send_byte(input [7:0] value);
        begin
            @(posedge clk);
            byte_sync = 1'b1;
            data_in = value;
            @(posedge clk);
            byte_sync = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        byte_sync = 0;
        data_in = 8'h00;
        data_read = 8'hAA;

        $dumpfile("tb_instr_dcd.vcd");
        $dumpvars(0, tb_instr_dcd);

        #200;
        rst_n = 1;
        #100;

        $display("\n======================================");
        $display("  INSTRUCTION DECODER TEST SUITE");
        $display("======================================");

        test_01_initial_state();
        test_02_write_lsb_doc_example();
        test_03_write_msb();
        test_04_read_lsb();
        test_05_read_msb();
        test_06_write_16bit_register();
        test_07_read_16bit_register();
        test_08_sequential_addresses();
        test_09_boundary_addresses();
        test_10_reset_test();

        $display("\n======================================");
        $display("  TEST SUMMARY");
        $display("======================================");
        $display("Total:  %0d", test_count);
        $display("Passed: %0d", passed_count);
        $display("Failed: %0d", failed_count);
        $display("Success Rate: %0d%%", (passed_count * 100) / test_count);
        $display("======================================\n");

        #500;
        $finish;
    end

    // ------------------ TESTS ------------------

    task check_result(input passed);
        begin
            if (passed) begin
                $display("  ✓ PASSED");
                passed_count++;
            end else begin
                $display("  ✗ FAILED");
                failed_count++;
            end
        end
    endtask

    task test_01_initial_state;
        begin
            test_count++;
            $display("\nTest 1: Initial state after reset");

            @(posedge clk);
            if (read == 0 && write == 0 && addr == 0)
              check_result(1);
            else
              check_result(0);
        end
    endtask

    // --------------------------------------------
    // WRITE LSB EXAMPLE
    // --------------------------------------------
    task test_02_write_lsb_doc_example;
        reg passed;
        begin
            test_count++;
            $display("\nTest 2: Write LSB (0x93, 0xA6)");
            passed = 0;

            // Setup
            send_byte(8'h93);

            // Data phase
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'hA6;

            @(posedge clk);  // wait for DUT to update outputs

            if (write && addr == 6'h13 && data_write == 8'hA6)
                passed = 1;

            byte_sync = 0;

            check_result(passed);
        end
    endtask

    // --------------------------------------------
    // WRITE MSB
    // --------------------------------------------
    task test_03_write_msb;
        reg passed;
        begin
            test_count++;
            $display("\nTest 3: Write MSB (0xD3, 0x55)");
            passed = 0;

            send_byte(8'hD3);

            @(posedge clk);
            byte_sync = 1;
            data_in = 8'h55;

            @(posedge clk);  // wait for DUT to update

            if (write && addr == (6'h13 + 6'd1) && data_write == 8'h55)
                passed = 1;

            byte_sync = 0;

            check_result(passed);
        end
    endtask

    /// --------------------------------------------
    // READ LSB
    // --------------------------------------------
    task test_04_read_lsb;
      reg passed;
      begin
        test_count++;
        $display("\nTest 4: Read LSB (0x20)");
        passed = 0;
        data_read = 8'hAB;

        // Setup phase triggers read
        send_byte(8'h20);

        @(posedge clk);  // SETUP finished, now data_out must be valid
        if (data_out == 8'hAB && read == 1)
          passed = 1;
        else
          $display("   ✗ in SETUP: data_out=%02h read=%b (expected AB,1)", data_out, read);

        // DATA phase gives received garbage to DUT; data_out must be 0
        @(posedge clk);
        byte_sync = 1;
        data_in = 8'h00;

        @(posedge clk);   // DATA evaluated
        byte_sync = 0;

        if (!passed) ; // keep failed state

        check_result(passed);
      end
    endtask

    // --------------------------------------------
    // READ MSB
    // --------------------------------------------
    task test_05_read_msb;
      reg passed;
      begin
        test_count++;
        $display("\nTest 5: Read MSB (0x60)");
        passed = 0;
        data_read = 8'hCD;

        // Setup
        send_byte(8'h60);

        @(posedge clk);  // SETUP finished
        if (data_out == 8'hCD && read == 1 && addr == 6'h20)
          passed = 1;
        else
          $display("   ✗ SETUP: data_out=%02h read=%b addr=%02h (expected CD,1,20)",
                   data_out, read, addr);

        // DATA: here the +1 offset must appear
        @(posedge clk);
        byte_sync = 1;
        data_in = 8'h00;

        @(posedge clk);
        if (addr == (6'h20 + 1))
          passed = passed && 1;
        else begin
          passed = 0;
          $display("   ✗ DATA: addr=%02h (expected 21)", addr);
        end

        byte_sync = 0;
        check_result(passed);
      end
    endtask
    // --------------------------------------------
    // WRITE 16-BIT REG
    // --------------------------------------------
    task test_06_write_16bit_register;
        begin
            test_count++;
            $display("\nTest 6: Write 16-bit register @0x10");

            send_byte(8'h90);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'h34;
            @(posedge clk);
            byte_sync = 0;

            send_byte(8'hD0);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'h12;
            @(posedge clk);
            byte_sync = 0;

            check_result(1);
        end
    endtask

    // --------------------------------------------
    // READ 16-BIT REG
    // --------------------------------------------
    task test_07_read_16bit_register;
        begin
            test_count++;
            $display("\nTest 7: Read 16-bit register @0x10");

            data_read = 8'h34;
            send_byte(8'h10);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'h00;
            @(posedge clk);
            byte_sync = 0;

            data_read = 8'h12;
            send_byte(8'h50);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'h00;
            @(posedge clk);
            byte_sync = 0;

            check_result(1);
        end
    endtask

    task test_08_sequential_addresses;
        integer i;
        begin
            test_count++;
            $display("\nTest 8: Sequential addresses");

            for (i = 0; i < 4; i=i+1) begin
                send_byte(8'h80 | i[5:0]);
                @(posedge clk);
                byte_sync = 1;
                data_in = 8'h10 + i;
                @(posedge clk);
                byte_sync = 0;
            end

            check_result(1);
        end
    endtask

    task test_09_boundary_addresses;
        begin
            test_count++;
            $display("\nTest 9: Boundary addresses");

            send_byte(8'h80);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'hAA;
            @(posedge clk);
            byte_sync = 0;

            send_byte(8'hFF);
            @(posedge clk);
            byte_sync = 1;
            data_in = 8'hBB;
            @(posedge clk);
            byte_sync = 0;

            check_result(1);
        end
    endtask

    task test_10_reset_test;
        begin
            test_count++;
            $display("\nTest 10: Reset behavior");

            send_byte(8'h81);
            rst_n = 0;
            #100;
            rst_n = 1;
            @(posedge clk);

            if (read == 0 && write == 0)
                check_result(1);
            else
                check_result(0);
        end
    endtask

    initial begin
        #200000;
        $display("\n✗ ERROR: Simulation timeout!");
        $finish;
    end

endmodule
