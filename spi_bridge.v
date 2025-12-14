module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,   // master out slave in
    output miso,  // master in slave out
    // internal facing signals
    output byte_sync,        // pulse = un nou byte primit
    output [7:0] data_in,    // ultimul byte primit
    input  [7:0] data_out    // byte-ul care va fi trimis următor
);

    //----------------------------------------------------------
    //  REGISTRE INTERNE
    //----------------------------------------------------------
    reg [7:0] shift_reg;    // buffer pentru MOSI
    reg [2:0] bit_cnt;      // numără biții 0..7
    reg [7:0] r_data_in;    // primul byte complet
    reg r_miso;             // linia de ieșire către master
    reg r_byte_sync;        // puls sincron cu clk
    reg byte_ready;         // puls nativ (pe domeniul sclk)

    //----------------------------------------------------------
    //  INPUT MOSI — domeniul SPI (pe SCLK)
    //----------------------------------------------------------
    always @(posedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            // Reset complet doar la power-on
            bit_cnt    <= 3'd0;
            shift_reg  <= 8'd0;
            byte_ready <= 1'b0;
        end else if (cs_n) begin
            // Cand CS_N e inactiv, resetam DOAR contorul si flag-ul,
            // DAR PASTRAM DATELE in shift_reg pentru a fi citite.
            bit_cnt    <= 3'd0;
            byte_ready <= 1'b0;
            // shift_reg ramane neschimbat
        end else begin
            // ciclul de citire pe frontul crescător SCLK
            shift_reg  <= {shift_reg[6:0], mosi};
            bit_cnt    <= bit_cnt + 3'd1;

            // după 8 biți → semnal „byte ready”
            if (bit_cnt == 3'd7)
                byte_ready <= 1'b1;
            else
                byte_ready <= 1'b0;
        end
    end

    //----------------------------------------------------------
    //  OUTPUT MISO — domeniul SPI (pe SCLK descrescător)
    //----------------------------------------------------------
    // Trimitere MSB first, sincron înapoi spre master
    //----------------------------------------------------------
    always @(negedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n || cs_n)
            r_miso <= 1'b0;
        else
            r_miso <= data_out[7 - bit_cnt];
    end

    //----------------------------------------------------------
    //  SINCRONIZARE CU CEASUL PERIFERIC (clk)
    //----------------------------------------------------------
    // „byte_ready” se întâmplă pe domeniul sclk,
    // deci trebuie adus ca puls în domeniul clk.
    //----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_byte_sync <= 1'b0;
            r_data_in   <= 8'd0;
        end else begin
            r_byte_sync <= byte_ready;       // puls de 1 clk
            if (byte_ready)
                r_data_in <= shift_reg;
        end
    end

    //----------------------------------------------------------
    //  CONECTAREA LA IEȘIRI
    //----------------------------------------------------------
    assign byte_sync = r_byte_sync;
    assign data_in   = r_data_in;
    assign miso      = r_miso;

endmodule