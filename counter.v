module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);
    // contorul principal
    reg[15:0] r_count;
    assign count_val = r_count;

    // prescalerul intern
    reg[15:0] r_psc;

    // numarul de cicluri necesar pentru incrementare
    wire[15:0] psc_limit = (16'd1 << prescale);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_count <= 16'd0;
            r_psc <= 16'd0;
        end else if(count_reset) begin
            r_count <= 16'd0;
            r_psc <= 16'd0;
        end else begin
            if(!en) begin // contor disabled
                r_psc <= 16'd0; // mentinem prescalerul sincron
            end else begin // contor enabled
                r_psc <= r_psc + 16'd1;

                // daca prescalerul a ajuns la limita, actualizam contorul
                if(r_psc == psc_limit - 1) begin
                    r_psc <= 16'd0;

                    if(upnotdown) begin
                        if (r_count == period)
                            r_count <= 16'd0; // overflow, deci reia de la 0
                        else
                            r_count <= r_count + 16'd1;
                    end
                    else begin
                        if (r_count == 0)
                            r_count <= period; // underflow deci, sarim la PERIOD
                        else
                            r_count <= r_count - 16'd1;
                    end
                end
            end
        end
    end

endmodule