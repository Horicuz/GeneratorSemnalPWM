module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);
    // Registri de iesire
    reg r_miso;
    reg r_byte_sync;
    reg [7:0] r_data_in;

    assign miso = r_miso;
    assign byte_sync = r_byte_sync;
    assign data_in = r_data_in;

    // Logica SPI - functioneaza pe sclk
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    
    // Counter pentru byte-uri complete (incrementat pe sclk domain)
    reg [7:0] byte_counter;
    reg [7:0] byte_counter_sync1;
    reg [7:0] byte_counter_sync2;
    reg [7:0] byte_counter_prev;
    
    // Date capturate
    reg [7:0] captured_data;

    // Logica pe rising edge sclk - captura date de pe mosi
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 0;
            shift_reg <= 0;
            byte_counter <= 0;
            captured_data <= 0;
        end else if (cs_n) begin
            bit_cnt <= 0;
        end else begin
            // Shift in MOSI bit
            shift_reg <= {shift_reg[6:0], mosi};
            
            if (bit_cnt == 7) begin
                bit_cnt <= 0;
                captured_data <= {shift_reg[6:0], mosi};
                byte_counter <= byte_counter + 1;
            end else begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end
    
    // Logica pe falling edge sclk - setare MISO
    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            r_miso <= 0;
        end else if (!cs_n) begin
            // Output next bit (MSB first)
            r_miso <= data_out[7 - bit_cnt];
        end
    end
    
    // Prima setare MISO cand CS devine activ
    always @(negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            // handled above
        end else begin
            r_miso <= data_out[7];
        end
    end

    // Sincronizare byte_counter catre domeniul clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter_sync1 <= 0;
            byte_counter_sync2 <= 0;
            byte_counter_prev <= 0;
            r_byte_sync <= 0;
            r_data_in <= 0;
        end else begin
            // Double-sync byte_counter
            byte_counter_sync1 <= byte_counter;
            byte_counter_sync2 <= byte_counter_sync1;
            byte_counter_prev <= byte_counter_sync2;
            
            // Detecteaza cand s-a completat un byte nou
            r_byte_sync <= 0;
            if (byte_counter_sync2 != byte_counter_prev) begin
                r_byte_sync <= 1;
                r_data_in <= captured_data;
            end
        end
    end

endmodule
