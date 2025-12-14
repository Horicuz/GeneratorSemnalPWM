module pwm_gen (
    input clk,
    input rst_n,
    input pwm_en,
    input [15:0] period,
    input [7:0]  functions,
    input [15:0] compare1,
    input [15:0] compare2,
    input [15:0] count_val,
    output pwm_out
);
    reg pwm_out_r;
    assign pwm_out = pwm_out_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_out_r <= 1'b0;
        else if (!pwm_en)
            pwm_out_r <= 1'b0;
        else begin
            if ((compare1 == 0) || (compare1 == compare2))
                pwm_out_r <= 1'b0;
            else begin
                case (functions[1:0])
                    // LEFT aligned – neschimbat
                    2'b00: pwm_out_r <= (count_val <= compare1);

                    // RIGHT aligned – MODIFICAT
                    // Activ dacă valoarea curentă este mai mare sau egală cu pragul
                    2'b01: pwm_out_r <= (count_val >= compare1);

                    // RANGE between – neschimbat
                    2'b10: pwm_out_r <=
                        (count_val >= compare1) && (count_val < compare2);

                    default: pwm_out_r <= 1'b0;
                endcase
            end
        end
    end
endmodule