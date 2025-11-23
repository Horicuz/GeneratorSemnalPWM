module instr_dcd (
    // Semnale de ceas
    input clk,
    input rst_n,

    // Semnale de la SPI
    input byte_sync,            // puls: un nou byte este disponibil
    input [7:0] data_in,        // byte-ul transmis de SPI
    output reg [7:0] data_out,  // byte transmis către SPI la citire

    // Semnale către/de la blocul de registre
    output reg read,            // puls de citire (1 ciclu)
    output reg write,           // puls de scriere (1 ciclu)
    output reg [5:0] addr,      // adresa registrului
    input  [7:0] data_read,     // valoare citită din registru
    output reg [7:0] data_write // byte transmis către registru
);

    // ==============================
    // DEFINIRE FSM
    // ==============================
    localparam S_IDLE = 1'b0;   // așteaptă BYTE-ul de setup
    localparam S_DATA = 1'b1;   // așteaptă BYTE-ul de date

    reg state;

    // Buffer pentru RW și HL – sunt păstrate între cele două faze
    reg rw_bit;        // 1 = write, 0 = read
    reg highlow_bit;   // 1 = MSB, 0 = LSB

    // Pulsuri interne — pentru a garanta durată 1 ciclu complet
    reg read_pulse;
    reg write_pulse;

    // ==============================
    // LOGICA FSM
    // ==============================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset complet
            state <= S_IDLE;
            addr <= 0;
            data_out <= 0;
            data_write <= 0;
            rw_bit <= 0;
            highlow_bit <= 0;

            // Reset impulsuri și ieșiri
            read <= 0;
            write <= 0;
            read_pulse <= 0;
            write_pulse <= 0;
        end else begin
            // -----------------------------------
            //  Pulsurile sunt generate astfel:
            //    - read/write = read_pulse/write_pulse
            //    - pulse-urile sunt resetate automat
            // -----------------------------------
            read  <= read_pulse;
            write <= write_pulse;

            // resetăm pulsurile după un ciclu complet
            read_pulse  <= 0;
            write_pulse <= 0;

            // Procesăm date doar când vine un byte nou
            if (byte_sync) begin
                case (state)

                    // ==========================
                    // FAZA 1 — SETUP BYTE
                    // ==========================
                    S_IDLE: begin
                        rw_bit      <= data_in[7];
                        highlow_bit <= data_in[6];
                        addr        <= data_in[5:0];

                        state <= S_DATA;
                    end

                    // ==========================
                    // FAZA 2 — DATA BYTE
                    // ==========================
                    S_DATA: begin
                        if (rw_bit) begin
                            // -------------------
                            // OPERAȚIE DE SCRIERE
                            // -------------------
                            data_write <= data_in;
                            write_pulse <= 1'b1;     // generăm pulsul
                        end else begin
                            // -------------------
                            // OPERAȚIE DE CITIRE
                            // -------------------
                            data_out <= data_read;
                            read_pulse <= 1'b1;      // generăm pulsul
                        end

                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end

endmodule
