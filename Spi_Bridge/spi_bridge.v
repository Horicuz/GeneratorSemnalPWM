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
    // declar registrii pentru a folosi in blocurile always
    reg r_miso;
    reg r_byte_sync;
    reg [7:0] r_data_in;

    // legan registrele interne la iesirile modulului
    assign miso = r_miso;
    assign byte_sync = r_byte_sync;
    assign data_in = r_data_in;

    // variabile interne folosite pentru logica
    reg [2:0] bit_cnt; // numara de la 0 la 7 (counter)
    reg [7:0] shift_reg; // retine datele de la MOSI
    reg sclk_prev; // retine starea anterioara a sclk

    wire sclk_rise = (sclk == 1) && (sclk_prev == 0);
    wire sclk_fall = (sclk == 0) && (sclk_prev == 1);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // reset
            sclk_prev <= 0;
            r_miso <= 0;
            r_byte_sync <= 0;
            r_data_in <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end
        else begin
            sclk_prev <= sclk;
            // pulsul de sync trebuie sa fie 0, il facem 1 doar cand terminam un byte
            r_byte_sync <= 0;

            // SPI functioneaza doar cand Chip Select (CS) este activ (pe Low, adica 0)
            // daca CS e inactiv (High), resetam contorul de biti
            if (cs_n) begin
                bit_cnt <= 0;
            end
            else begin
                // stan MISO pentru primul bit cand CS este activ si bit_cnt = 0
                if (bit_cnt == 0 && !sclk) begin
                    r_miso <= data_out[7];
                end

                if(sclk_rise) begin
                    // pastram ultimii 7 biti si adaugam ultimul bit la sfarsit
                    shift_reg <= {shift_reg[6:0], mosi};

                    // daca am primit 8 biti
                    if(bit_cnt == 7) begin
                        bit_cnt <= 0;
                        r_data_in <= {shift_reg[6:0], mosi};
                        r_byte_sync <= 1;
                    end
                    else begin
                        // incrementam contorul
                        bit_cnt <= bit_cnt + 1;
                    end
                end

                if(sclk_fall) begin
                    // trimitem bit-ul corect din data_out MSB first
                    // cand bit_cnt este 0, trimitem bitul 7. cand e 1, trimitem 6.
                    // (formula este deci: 7 - bit_cnt)
                    r_miso <= data_out[7 - bit_cnt];
                end
            end
        end
    end

endmodule