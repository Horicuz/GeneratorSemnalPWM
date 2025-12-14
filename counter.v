module counter (
    // peripheral clock signals
    input  wire        clk,
    input  wire        rst_n,
    // register facing signals
    output wire [15:0] count_val,
    input  wire [15:0] period,
    input  wire        en,
    input  wire        count_reset,
    input  wire        upnotdown,
    input  wire [7:0]  prescale
);

    // ---------------------------
    // Registre interne
    // ---------------------------
    reg [15:0] count_val_r;
    reg [7:0]  prescale_cnt;

    // Conectăm registrul intern la ieșire
    assign count_val = count_val_r;

    // ---------------------------
    // Logică principală
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset asincron (Hardware Reset)
            count_val_r  <= 16'd0;
            prescale_cnt <= 8'd0;
        end else begin
            if (count_reset) begin
                // Reset sincron (din Software/Registru)
                count_val_r  <= 16'd0;
                prescale_cnt <= 8'd0;
            end else if (en) begin
                // Logica de Prescaler (Liniar: Divide cu prescale + 1)
                if (prescale_cnt == prescale) begin
                    // Prescaler a atins limita, executăm un "tick" de numărare
                    prescale_cnt <= 8'd0;

                    if (upnotdown) begin
                        // UP MODE: 0 -> period
                        if (count_val_r == period)
                            count_val_r <= 16'd0;
                        else
                            count_val_r <= count_val_r + 1'b1;
                    end else begin
                        // DOWN MODE: period -> 0
                        if (count_val_r == 0)
                            count_val_r <= period;
                        else
                            count_val_r <= count_val_r - 1'b1;
                    end
                end else begin
                    // Încă nu a trecut timpul, incrementăm prescalerul
                    prescale_cnt <= prescale_cnt + 1'b1;
                end
            end
            // else (!en):
            // Contorul 'îngheață' (păstrează valoarea curentă).
            // Dacă dorești comportamentul prietenului (reset la disable), 
            // poți adăuga aici un `else prescale_cnt <= 0;` dar nu e obligatoriu.
        end
    end

endmodule