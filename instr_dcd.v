module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,
    // register access signals
    output read,
    output write,
    output [5:0] addr,
    input  [7:0] data_read,
    output [7:0] data_write
);

    // ieșiri ca wire, conduse din registre interne
    reg        read_r, write_r;
    reg [5:0]  addr_r;
    reg [7:0]  data_out_r, data_write_r;

    assign read       = read_r;
    assign write      = write_r;
    assign addr       = addr_r;
    assign data_out   = data_out_r;
    assign data_write = data_write_r;

    // FSM
    localparam S_CMD  = 1'b0;
    localparam S_DATA = 1'b1;

    reg state;
    reg rw_bit;  // 1=write, 0=read (latched din command byte)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_CMD;
            rw_bit       <= 1'b0;
            addr_r       <= 6'd0;
            data_out_r   <= 8'd0;
            data_write_r <= 8'd0;
            read_r       <= 1'b0;
            write_r      <= 1'b0;

        end else begin
            // pulse de 1 ciclu
            read_r  <= 1'b0;
            write_r <= 1'b0;

            if (byte_sync) begin
                case (state)
                    // Primul byte: command
                    S_CMD: begin
                        rw_bit <= data_in[7];          // CORE SPOT: latchează RW din command
                        addr_r <= data_in[5:0];        // ignoră high/low; adresa e directă
                        state  <= S_DATA;
                    end

                    // Al doilea byte: data
                    S_DATA: begin
                        if (rw_bit) begin
                            // WRITE
                            data_write_r <= data_in;
                            write_r      <= 1'b1;
                        end else begin
                            // READ
                            data_out_r <= data_read;
                            read_r     <= 1'b1;
                        end
                        state <= S_CMD;
                    end
                endcase
            end
        end
    end

endmodule