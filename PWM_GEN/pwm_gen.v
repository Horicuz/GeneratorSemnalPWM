module pwm_gen (
    // Semnale ceas periferic
    input clk,
    input rst_n,

    // Configurare din registri
    input pwm_en,
    input [15:0] period,
    input [7:0]  functions,      // bit1 = unaligned, bit0 = align L/R
    input [15:0] compare1,
    input [15:0] compare2,

    // Valoarea curentă a numărătorului
    input [15:0] count_val,

    // Ieșirea către exterior
    output reg pwm_out
);

    wire unaligned = functions[1];
    wire align_lr  = functions[0]; // 0 = stânga, 1 = dreapta

    // Logica PWM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 0;
        end else begin

            if (!pwm_en) begin
                // PWM dezactivat → linia rămâne blocată
                pwm_out <= pwm_out;
            end else begin

                // -------------------------
                // RESTART LA OVERFLOW (count_val == period)
                // -------------------------
                if (count_val == period) begin
                    if (!unaligned) begin
                        // PWM ALINIAT
                        pwm_out <= (align_lr == 1'b0) ? 1'b1 : 1'b0;
                    end else begin
                        // PWM NEALINIAT
                        pwm_out <= 1'b0;
                    end
                end

                // -------------------------
                // PWM ALINIAT
                // -------------------------
                if (!unaligned) begin
                    if (count_val == compare1)
                        pwm_out <= ~pwm_out;   // toggle
                end

                // -------------------------
                // PWM NEALINIAT
                // -------------------------
                else begin
                    if (count_val == compare1)
                        pwm_out <= 1'b1;

                    if (count_val == compare2)
                        pwm_out <= 1'b0;
                end

            end
        end
    end

endmodule
