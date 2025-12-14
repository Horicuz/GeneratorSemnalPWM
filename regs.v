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

    // 1. DEFINIRE REGISTRE INTERNE (Prefix 'r_')
    // Acestea stocheaza valoarea. Nu putem folosi numele din porturi direct.
    reg [7:0]  r_data_read;
    
    reg [15:0] r_period;
    reg        r_en;
    reg        r_count_reset;
    reg        r_upnotdown;
    reg [7:0]  r_prescale;
    reg        r_pwm_en;
    reg [7:0]  r_functions;
    reg [15:0] r_compare1;
    reg [15:0] r_compare2;

    // 2. CONECTARE REGISTRE LA IESIRI (WIRE)
    // Aici facem legatura dintre memoria interna si pinii modulului
    assign data_read   = r_data_read;
    assign period      = r_period;
    assign en          = r_en;
    assign count_reset = r_count_reset;
    assign upnotdown   = r_upnotdown;
    assign prescale    = r_prescale;
    assign pwm_en      = r_pwm_en;
    assign functions   = r_functions;
    assign compare1    = r_compare1;
    assign compare2    = r_compare2;

    // ------------------------------------------------------------------------
    // LOGICA DE SCRIERE (Write)
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_period      <= 16'h0000;
            r_en          <= 1'b0;
            r_count_reset <= 1'b0;
            r_upnotdown   <= 1'b0;
            r_prescale    <= 8'h00;
            r_pwm_en      <= 1'b0;
            r_functions   <= 8'h00;
            r_compare1    <= 16'h0000;
            r_compare2    <= 16'h0000;
        end else begin
            // Auto-clear
            r_count_reset <= 1'b0; 

            if (write) begin
                case (addr)
                    // PERIOD low byte
                    6'h00: r_period[7:0]    <= data_write;
                    // PERIOD high byte
                    6'h01: r_period[15:8]   <= data_write;
                    // COUNTER_EN (1 bit)
                    6'h02: r_en             <= data_write[0];
                    // COMPARE1 low si high byte
                    6'h03: r_compare1[7:0]  <= data_write;
                    6'h04: r_compare1[15:8] <= data_write;
                    // COMPARE2 low si high byte
                    6'h05: r_compare2[7:0]  <= data_write;
                    6'h06: r_compare2[15:8] <= data_write;
                    // COUNTER_RESET - write-only, orice scriere produce un impuls
                    6'h07: r_count_reset    <= 1'b1;
                    // PRESCALE (8 biti)
                    6'h0A: r_prescale       <= data_write;
                    // UPNOTDOWN (1 bit)
                    6'h0B: r_upnotdown      <= data_write[0];
                    // PWM_EN (1 bit)
                    6'h0C: r_pwm_en         <= data_write[0];
                    // FUNCTIONS
                    6'h0D: r_functions      <= data_write;
                endcase
            end
        end
    end

    // ------------------------------------------------------------------------
    // LOGICA DE CITIRE (Read)
    // ------------------------------------------------------------------------
    // Multiplexor combinațional mare
    always @(*) begin
        if (!read) begin
            r_data_read = 8'h00;
        end else begin
            case (addr)
                6'h00: r_data_read = r_period[7:0];
                6'h01: r_data_read = r_period[15:8];
                6'h02: r_data_read = {7'd0, r_en};
                6'h03: r_data_read = r_compare1[7:0];
                6'h04: r_data_read = r_compare1[15:8];
                6'h05: r_data_read = r_compare2[7:0];
                6'h06: r_data_read = r_compare2[15:8];
                6'h07: r_data_read = 8'h00;             
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