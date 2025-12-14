module spi_bridge (
    // peripheral clock signals
    input  wire       clk,
    input  wire       rst_n,
    // SPI master facing signals
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    output wire       miso,
    // internal facing
    output wire       byte_sync,
    output wire [7:0] data_in,
    input  wire [7:0] data_out
);

    // ------------------------------------------------------------------------
    // DOMENIUL SPI (SCLK)
    // ------------------------------------------------------------------------
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    
    // In loc de un counter mare, folosim un singur bit care se inverseaza.
    // Este matematic echivalent cu bitul 0 al counter-ului tau.
    reg       toggle_flag; 
    
    // Buffer pentru a tine datele stabile pana le citeste CLK (Secretul succesului tau)
    reg [7:0] captured_data;
    
    reg r_miso;

    // Logica de captura si Toggle
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt       <= 3'd0;
            shift_reg     <= 8'd0;
            toggle_flag   <= 1'b0;
            captured_data <= 8'd0;
        end else if (cs_n) begin
            // Resetam doar indexul bitilor cand CS e inactiv
            bit_cnt <= 3'd0;
        end else begin
            // Shiftam datele
            shift_reg <= {shift_reg[6:0], mosi};
            
            if (bit_cnt == 3'd7) begin
                bit_cnt <= 3'd0;
                // 1. Salvam datele intr-un buffer stabil
                captured_data <= {shift_reg[6:0], mosi};
                // 2. Semnalizam "GATA" inversand bitul (Toggle)
                // Asta e mult mai sigur hardware decat "byte_counter + 1"
                toggle_flag <= ~toggle_flag;
            end else begin
                bit_cnt <= bit_cnt + 3'd1;
            end
        end
    end
    
    // Logica MISO (Exact ca in varianta ta)
    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            r_miso <= 1'b0;
        end else if (!cs_n) begin
            r_miso <= data_out[7 - bit_cnt];
        end
    end
    
    // Setup initial MISO (Exact ca in varianta ta)
    always @(negedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
             // nimic
        end else begin
            r_miso <= data_out[7];
        end
    end

    // ------------------------------------------------------------------------
    // DOMENIUL SISTEM (CLK)
    // ------------------------------------------------------------------------
    reg       toggle_sync1;
    reg       toggle_sync2;
    reg       toggle_prev;
    
    reg       r_byte_sync;
    reg [7:0] r_data_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_sync1 <= 1'b0;
            toggle_sync2 <= 1'b0;
            toggle_prev  <= 1'b0;
            r_byte_sync  <= 1'b0;
            r_data_in    <= 8'd0;
        end else begin
            // 1. Sincronizam doar 1 bit (Toggle Flag) - Sigur Hardware
            toggle_sync1 <= toggle_flag;
            toggle_sync2 <= toggle_sync1;
            
            // 2. Memoram starea anterioara
            toggle_prev  <= toggle_sync2;
            
            // 3. Detectam orice schimbare (0->1 sau 1->0)
            // Asta e echivalent cu detectarea incrementarii counter-ului tau
            r_byte_sync <= 1'b0;
            
            if (toggle_sync2 != toggle_prev) begin
                r_byte_sync <= 1'b1;
                // Citim din bufferul stabilizat
                r_data_in   <= captured_data;
            end
        end
    end

    // Iesiri
    assign miso      = r_miso;
    assign byte_sync = r_byte_sync;
    assign data_in   = r_data_in;

endmodule