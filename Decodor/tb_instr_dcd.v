`timescale 1ns/1ps

module tb_instr_dcd;

    // ===============================
    // DUT signals
    // ===============================
    reg clk;
    reg rst_n;

    reg byte_sync;
    reg [7:0] data_in;
    wire [7:0] data_out;

    wire read;
    wire write;
    wire [5:0] addr;
    reg  [7:0] data_read;
    wire [7:0] data_write;

    // Instantiate DUT
    instr_dcd DUT (
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

    // ===============================
    // Clock
    // ===============================
    always #5 clk = ~clk;   // 100 MHz

    // ===============================
    // Test variables
    // ===============================
    integer errors = 0;
    integer test_id = 0;

    // ===============================
    // TASKS
    // ===============================

    // Task generic: send SPI byte (with byte_sync pulse)
    task send_byte;
        input [7:0] byte;
    begin
        @(posedge clk);
        data_in = byte;
        byte_sync = 1;
        @(posedge clk);
        byte_sync = 0;
    end
    endtask


    // ---------------------------
    // TASK: test write operation
    // ---------------------------
    task test_write;
        input [5:0] a;
        input [7:0] val;

        reg [7:0] setup;
    begin
        test_id = test_id + 1;
        $display("\n=== TEST %0d: WRITE addr=%0d val=0x%02X ===", test_id, a, val);

        setup = {1'b1,     // RW=1 (write)
                 1'b0,     // HL bit (nu conteaza)
                 a};

        // 1) Send setup byte
        send_byte(setup);

        // 2) Send data byte
        send_byte(val);

        // Check if write pulse is high for 1 cycle
        @(posedge clk);
        if (write !== 1) begin
            $display("ERROR: write pulse missing!");
            errors = errors + 1;
        end

        if (data_write !== val) begin
            $display("ERROR: wrong data_write: got 0x%02X, expected 0x%02X",
                     data_write, val);
            errors = errors + 1;
        end

        @(posedge clk);
        if (write !== 0) begin
            $display("ERROR: write pulse not cleared after 1 cycle!");
            errors = errors + 1;
        end
    end
    endtask


    // ---------------------------
    // TASK: test read operation
    // ---------------------------
    task test_read;
        input [5:0] a;
        input [7:0] reg_val;

        reg [7:0] setup;
    begin
        test_id = test_id + 1;
        $display("\n=== TEST %0d: READ addr=%0d expecting=0x%02X ===",
                 test_id, a, reg_val);

        setup = {1'b0,     // RW=0 (read)
                 1'b0,     // HL = 0 (nu conteaza)
                 a};

        // 1) pregătim valoarea pe magistrală
        data_read = reg_val;

        // 2) send setup
        send_byte(setup);

        // 3) send dummy byte
        send_byte(8'h00);

        // 4) Check read pulse
        @(posedge clk);
        if (read !== 1) begin
            $display("ERROR: read pulse missing!");
            errors = errors + 1;
        end

        if (data_out !== reg_val) begin
            $display("ERROR: data_out wrong: got 0x%02X expected 0x%02X",
                     data_out, reg_val);
            errors = errors + 1;
        end

        @(posedge clk);
        if (read !== 0) begin
            $display("ERROR: read pulse not cleared!");
            errors = errors + 1;
        end
    end
    endtask


    // ===============================
    // INITIAL BLOCK
    // ===============================
    initial begin
        $display("=== STARTING TESTBENCH ===");

        clk = 0;
        rst_n = 0;
        byte_sync = 0;
        data_in = 0;
        data_read = 0;

        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;

        // ======================================
        // RUN TESTS
        // ======================================

        // Basic tests
        test_write(6'd3, 8'hA5);
        test_write(6'd12, 8'hFF);

        test_read(6'd7,  8'h11);
        test_read(6'd20, 8'hCD);

        // Randomized tests
        repeat(10) begin
            test_write($random % 64, $random);
            test_read ($random % 64, $random);
        end

        // ======================================
        // FINAL RESULTS
        // ======================================

        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ✓ ✓ ✓ ===");
        else
            $display("\n=== TESTS FAILED: %0d ERRORS ===", errors);

        $finish;
    end

    // Timeout global (safety)
    initial begin
        #50000;
        $display("TIMEOUT! Something is wrong.");
        $finish;
    end

endmodule
