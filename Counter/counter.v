module counter (
    // peripheral clock signals
    input clk,
    input rst_n,

    // register-facing signals
    output reg [15:0] count_val,
    input [15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input [7:0] prescale
);

    // internal prescaler counter
    // prescale_cnt counts from 0 to prescale
    reg [7:0] prescale_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // full asynchronous reset
            count_val    <= 16'd0;
            prescale_cnt <= 8'd0;

        end else begin

            // counter_reset only resets the counter,
            // does NOT reset other peripheral registers.
            if (count_reset) begin
                count_val    <= 16'd0;
                prescale_cnt <= 8'd0;
            end 

            // counter logic only when enabled
            else if (en) begin

                // prescaler reached → perform one increment/decrement
                if (prescale_cnt == prescale) begin
                    prescale_cnt <= 0;

                    // counting direction
                    if (upnotdown) begin
                        // count up
                        if (count_val == period)
                            count_val <= 16'd0;       // OVERFLOW → wrap
                        else
                            count_val <= count_val + 1;

                    end else begin
                        // count down
                        if (count_val == 0)
                            count_val <= period;      // UNDERFLOW → wrap
                        else
                            count_val <= count_val - 1;
                    end
                end

                // prescaler has not expired → keep counting internal cycles
                else begin
                    prescale_cnt <= prescale_cnt + 1;
                end

            end 
            // if en == 0 → counter is frozen (keeps its value)
        end
    end

endmodule
