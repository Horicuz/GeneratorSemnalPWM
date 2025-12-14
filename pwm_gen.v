module pwm_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pwm_en,
    input  wire [15:0] period,
    input  wire [7:0]  functions, // [1]=AlignMode, [0]=AlignRight
    input  wire [15:0] compare1,
    input  wire [15:0] compare2,
    input  wire [15:0] count_val,
    output wire        pwm_out
);

    // Revenim la logica combinationala pentru a avea ZERO latenta
    // (Necesar pentru a trece Testbench-ul strict)
    reg r_pwm_out;
    assign pwm_out = r_pwm_out;

    // Decodare functii pentru citibilitate
    wire [1:0] mode_sel = functions[1:0]; 

    localparam MODE_LEFT_ALIGNED  = 2'b00;
    localparam MODE_RIGHT_ALIGNED = 2'b01;
    localparam MODE_RANGE         = 2'b10;

    // Folosim always @(*) in loc de @(posedge clk)
    always @(*) begin
        // Default value
        r_pwm_out = 1'b0;

        if (!rst_n || !pwm_en) begin
            r_pwm_out = 1'b0;
        end else if ((compare1 == 0) || (compare1 == compare2)) begin
            r_pwm_out = 1'b0;
        end else begin
            case (mode_sel)
                // LEFT aligned: Activ de la 0 pana la compare1
                MODE_LEFT_ALIGNED: 
                    r_pwm_out = (count_val <= compare1);

                // RIGHT aligned: Activ de la compare1 pana la final
                MODE_RIGHT_ALIGNED: 
                    r_pwm_out = (count_val >= compare1);

                // RANGE (Unaligned): Activ intre cele doua praguri
                MODE_RANGE: 
                    r_pwm_out = (count_val >= compare1) && (count_val < compare2);

                default: r_pwm_out = 1'b0;
            endcase
        end
    end

endmodule