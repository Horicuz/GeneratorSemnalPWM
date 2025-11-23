module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output[7:0] data_read,
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions,
    output[15:0] compare1,
    output[15:0] compare2
);
    /*
        All registers that appear in this block should be similar to this. Please try to abide
        to sizes as specified in the architecture documentation.
    */
    reg[15:0] r_period;
    reg r_en;
    reg r_count_reset;
    reg r_upnotdown;
    reg[7:0] r_prescale;
    reg r_pwm_en;
    reg[7:0] r_functions;
    reg[15:0] r_compare1;
    reg[15:0] r_compare2;
    reg[7:0] r_data_read;

    assign period = r_period;
    assign en = r_en;
    assign count_reset = r_count_reset;
    assign upnotdown = r_upnotdown;
    assign prescale = r_prescale;
    assign pwm_en = r_pwm_en;
    assign functions = r_functions;
    assign compare1 = r_compare1;
    assign compare2 = r_compare2;
    assign data_read = r_data_read;

    // aici avem logica de scriere in registri
    // se activeaza doar cand write este 1
    // selecteaza registrul din addr
    // fiecare registru e scris pe cate un ciclu de clk
    // resetul pune toate valorile la 0
    // count_reset trebuie sa faca un impuls de un ciclu, deci il resetam la 0 la fiecare clk
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_period <= 16'h0000;
            r_en <= 1'b0;
            r_count_reset <= 1'b0;
            r_upnotdown <= 1'b0;
            r_prescale <= 8'h00;
            r_pwm_en <= 1'b0;
            r_functions <= 8'h00;
            r_compare1 <= 16'h0000;
            r_compare2 <= 16'h0000;
        end else begin
            // count_reset este write-only si trebuie sa fie un puls, deci se reseteaza dupa fiecare ciclu
            r_count_reset <= 1'b0;

            if (write) begin
                case (addr)
                    // PERIOD low byte
                    6'h00: r_period[7:0]  <= data_write;
                    // PERIOD high byte
                    6'h01: r_period[15:8] <= data_write;
                    // COUNTER_EN (1 bit)
                    6'h02: r_en <= data_write[0];
                    // COMPARE1 low si high byte
                    6'h03: r_compare1[7:0] <= data_write;
                    6'h04: r_compare1[15:8] <= data_write;
                    // COMPARE2 low si high byte
                    6'h05: r_compare2[7:0] <= data_write;
                    6'h06: r_compare2[15:8] <= data_write;
                    // COUNTER_RESET - write-only, orice scriere produce un impuls
                    6'h07: r_count_reset <= 1'b1;
                    // PRESCALE (8 biti)
                    6'h0A: r_prescale <= data_write;
                    // UPNOTDOWN (1 bit)
                    6'h0B: r_upnotdown <= data_write[0];
                    // PWM_EN (1 bit)
                    6'h0C: r_pwm_en <= data_write[0];
                    // FUNCTIONS (2 biti folositi, dar registrul e pe 8)
                    6'h0D: r_functions <= data_write;
                endcase
            end
        end
    end

    // logica de citire
    // daca read este 0 -> returnam 0
    // daca este 1 -> multiplexam in functie de addr
    // registrele de 16 biti sunt impartite in LSB/MSB la adrese consecutive
    // adrese invalide -> 0
    always @(*) begin
        if(!read)
            r_data_read = 8'h00;
        else begin
            case(addr)
                6'h00: r_data_read = r_period[7:0];
                6'h01: r_data_read = r_period[15:8];
                6'h02: r_data_read = {7'd0, r_en};
                6'h03: r_data_read = r_compare1[7:0];
                6'h04: r_data_read = r_compare1[15:8];
                6'h05: r_data_read = r_compare2[7:0];
                6'h06: r_data_read = r_compare2[15:8];
                // COUNTER_RESET este write-only, la citire intoarce 0
                6'h07: r_data_read = 8'h00;
                // COUNTER_VAL este read-only, vine din counter
                6'h08: r_data_read = counter_val[7:0];
                6'h09: r_data_read = counter_val[15:8];
                6'h0A: r_data_read = r_prescale;
                6'h0B: r_data_read = {7'd0, r_upnotdown};
                6'h0C: r_data_read = {7'd0, r_pwm_en};
                6'h0D: r_data_read = r_functions;
                default: r_data_read = 8'h00;
            endcase
        end
    end
endmodule