module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output [15:0] count_val,
    input  [15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input [7:0] prescale
);

    // ---------------------------
    // Registre interne
    // ---------------------------
    reg [15:0] count_val_r;
    reg [7:0]  prescale_cnt;
    assign count_val = count_val_r;

    // ---------------------------
    // Logică principală
    // ---------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_val_r  <= 16'd0;
            prescale_cnt <= 8'd0;

        end else begin

            if (count_reset) begin
                count_val_r  <= 16'd0;
                prescale_cnt <= 8'd0;

            end else if (en) begin

                if (prescale_cnt == prescale) begin
                    prescale_cnt <= 8'd0;

                    if (upnotdown) begin
                        // UP → numără 0 ... period (inclusive)
                        // Modificare: Reset doar cand EGAL cu period
                        if (count_val_r == period) 
                            count_val_r <= 16'd0;
                        else
                            count_val_r <= count_val_r + 1'b1;

                    end else begin
                        // DOWN → numără period ... 0
                        if (count_val_r == 0)
                            count_val_r <= period;
                        else
                            count_val_r <= count_val_r - 1'b1;
                    end

                end else begin
                    prescale_cnt <= prescale_cnt + 1'b1;
                end
            end
        end
    end

endmodule