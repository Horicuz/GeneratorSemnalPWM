module instr_dcd (
    // peripheral clock signals
    input  wire       clk,
    input  wire       rst_n,
    // towards SPI slave interface signals
    input  wire       byte_sync,    // Puls primit de la SPI cand un byte e gata
    input  wire [7:0] data_in,      // Byte-ul primit
    output wire [7:0] data_out,     // Byte-ul de trimis inapoi (MISO)
    // register access signals
    output wire       read,         // Semnal activ 1 ciclu pentru citire
    output wire       write,        // Semnal activ 1 ciclu pentru scriere
    output wire [5:0] addr,         // Adresa registrului tinta
    input  wire [7:0] data_read,    // Datele primite de la registre
    output wire [7:0] data_write    // Datele de scris in registre
);

    // ------------------------------------------------------------------------
    // REGISTRE INTERNE
    // ------------------------------------------------------------------------
    reg       r_read;
    reg       r_write;
    reg [5:0] r_addr;
    reg [7:0] r_data_out;   // Buffer pentru datele de iesire (stabilitate)
    reg [7:0] r_data_write;

    // Conectare la iesiri
    assign read       = r_read;
    assign write      = r_write;
    assign addr       = r_addr;
    assign data_out   = r_data_out;
    assign data_write = r_data_write;

    // ------------------------------------------------------------------------
    // FSM (State Machine)
    // ------------------------------------------------------------------------
    localparam S_CMD  = 1'b0; // Asteptam comanda (Primul byte)
    localparam S_DATA = 1'b1; // Procesam datele (Al doilea byte)

    reg state;
    reg rw_bit; // 1 = Write, 0 = Read (extras din comanda)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_CMD;
            rw_bit       <= 1'b0;
            r_addr       <= 6'd0;
            r_data_out   <= 8'd0;
            r_data_write <= 8'd0;
            r_read       <= 1'b0;
            r_write      <= 1'b0;
        end else begin
            // Pulsurile de control sunt active doar 1 ciclu
            r_read  <= 1'b0;
            r_write <= 1'b0;

            if (byte_sync) begin
                case (state)
                    // --------------------------------------------------------
                    // STARE 1: Primire Comanda (Adresa + RW bit)
                    // --------------------------------------------------------
                    S_CMD: begin
                        // Format comanda: [7]=RW, [6]=Dummy, [5:0]=ADDR
                        rw_bit <= data_in[7];     // 1=Write, 0=Read
                        r_addr <= data_in[5:0];   // Salvam adresa
                        state  <= S_DATA;         // Trecem la faza de date
                    end

                    // --------------------------------------------------------
                    // STARE 2: Transfer Date (Write sau Read)
                    // --------------------------------------------------------
                    S_DATA: begin
                        if (rw_bit) begin
                            // --- OPERATIE SCRIERE ---
                            r_data_write <= data_in; // Luam datele de la SPI
                            r_write      <= 1'b1;    // Activam semnalul de scriere
                        end else begin
                            // --- OPERATIE CITIRE ---
                            r_data_out   <= data_read; // Capturam datele din registre
                            r_read       <= 1'b1;      // (Optional) semnalizam citirea
                        end
                        // Ne intoarcem sa asteptam urmatoarea comanda
                        state <= S_CMD;
                    end
                endcase
            end
        end
    end

endmodule