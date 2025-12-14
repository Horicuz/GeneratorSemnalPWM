module regs (
    // peripheral clock signals
    input  wire        clk,
    input  wire        rst_n,
    // decoder facing signals
    input  wire        read,
    input  wire        write,
    input  wire [5:0]  addr,
    output reg  [7:0]  data_read, // Logică combinațională
    input  wire [7:0]  data_write,
    // counter programming signals
    input  wire [15:0] counter_val,
    output wire [15:0] period,
    output wire        en,
    output wire        count_reset,
    output wire        upnotdown,
    output wire [7:0]  prescale,
    // PWM signal programming values
    output wire        pwm_en,
    output wire [7:0]  functions,
    output wire [15:0] compare1,
    output wire [15:0] compare2
);

    // ------------------------------------------------------------------------
    // REGISTRE INTERNE
    // ------------------------------------------------------------------------
    reg [15:0] r_period;
    reg        r_en;
    reg        r_count_reset;
    reg        r_upnotdown;
    reg [7:0]  r_prescale;
    reg        r_pwm_en;
    reg [7:0]  r_functions;
    reg [15:0] r_compare1;
    reg [15:0] r_compare2;

    // ------------------------------------------------------------------------
    // CONECTARI CATRE IESIRI
    // ------------------------------------------------------------------------
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
            // Puls de auto-clear pentru resetul contorului
            r_count_reset <= 1'b0; 

            if (write) begin
                case (addr)
                    6'h00: r_period[7:0]    <= data_write;
                    6'h01: r_period[15:8]   <= data_write;
                    6'h02: r_en             <= data_write[0];
                    6'h03: r_compare1[7:0]  <= data_write;
                    6'h04: r_compare1[15:8] <= data_write;
                    6'h05: r_compare2[7:0]  <= data_write;
                    6'h06: r_compare2[15:8] <= data_write;
                    6'h07: r_count_reset    <= 1'b1; // Write-Only (Pulse)
                    6'h0A: r_prescale       <= data_write;
                    6'h0B: r_upnotdown      <= data_write[0];
                    6'h0C: r_pwm_en         <= data_write[0];
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
            data_read = 8'h00;
        end else begin
            case (addr)
                6'h00: data_read = r_period[7:0];
                6'h01: data_read = r_period[15:8];
                6'h02: data_read = {7'd0, r_en};
                6'h03: data_read = r_compare1[7:0];
                6'h04: data_read = r_compare1[15:8];
                6'h05: data_read = r_compare2[7:0];
                6'h06: data_read = r_compare2[15:8];
                6'h07: data_read = 8'h00;             // Write-Only
                6'h08: data_read = counter_val[7:0];  // Read-Only (din counter)
                6'h09: data_read = counter_val[15:8]; // Read-Only (din counter)
                6'h0A: data_read = r_prescale;
                6'h0B: data_read = {7'd0, r_upnotdown};
                6'h0C: data_read = {7'd0, r_pwm_en};
                6'h0D: data_read = r_functions;
                default: data_read = 8'h00;
            endcase
        end
    end

endmodule