module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);
    wire align_mode = functions[1]; // 0 = aliniat, 1 = nealiniat
    wire align_right = functions[0]; // 0 = left, 1 = right

    reg r_pwm;

    always @(*) begin
        if (!pwm_en) begin
            r_pwm = 1'b0;
        end else if (compare1 == compare2) begin
            // Caz special: daca compare1 == compare2, PWM e mereu 0
            // (intervalul de activare are latime 0)
            r_pwm = 1'b0;
        end else begin
            if (!align_mode) begin
                // Mod aliniat
                if (!align_right) begin
                    // Align left: PWM e HIGH cand count_val <= compare1
                    // Caz special: daca compare1 == 0, PWM nu se activeaza niciodata
                    if (compare1 == 16'd0)
                        r_pwm = 1'b0;
                    else if (count_val <= compare1)
                        r_pwm = 1'b1;
                    else
                        r_pwm = 1'b0;
                end else begin
                    // Align right: PWM e HIGH cand count_val >= compare1
                    if (count_val < compare1)
                        r_pwm = 1'b0;
                    else
                        r_pwm = 1'b1;
                end
            end else begin
                // Mod nealiniat: HIGH intre compare1 si compare2
                if (count_val < compare1) begin
                    r_pwm = 1'b0;
                end else if (count_val < compare2) begin
                    r_pwm = 1'b1;
                end else begin
                    r_pwm = 1'b0;
                end
            end
        end
    end

    assign pwm_out = r_pwm;
endmodule
