/*
    TOP.V - Top Level Module
    Integreaza modulele: SPI Bridge, Instruction Decoder, Register File, Counter, PWM Gen.
*/

module top(
    // peripheral clock signals
    input  wire clk,
    input  wire rst_n,
    // SPI master facing signals
    input  wire sclk,
    input  wire cs_n,
    input  wire miso,   // TB -> DUT (Functioneaza ca MOSI)
    output wire mosi,   // DUT -> TB (Functioneaza ca MISO)
    // peripheral signals
    output wire pwm_out
);

    // ------------------------------------------------------------------------
    // SEMNALE INTERNE
    // ------------------------------------------------------------------------
    
    // SPI / Decoder interface
    wire       byte_sync;
    wire [7:0] data_in;
    wire [7:0] data_out;
    wire       read;
    wire       write;
    wire [5:0] addr;
    wire [7:0] data_read;
    wire [7:0] data_write;

    // Counter / Timer signals
    wire [15:0] counter_val;
    wire [15:0] period;
    wire        en;
    wire        count_reset;
    wire        upnotdown;
    wire [7:0]  prescale;

    // PWM signals
    wire        pwm_en;
    wire [7:0]  functions;
    wire [15:0] compare1;
    wire [15:0] compare2;

    // ------------------------------------------------------------------------
    // INSTANTIERE MODULE
    // ------------------------------------------------------------------------

    // 1. SPI BRIDGE
    // Conecteaza lumea externa SPI la magistrala interna de date
    spi_bridge i_spi_bridge (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        // Atentie la maparea inversa impusa de schelet:
        .mosi(miso),   // Inputul modulului primeste date din pinul 'miso'
        .miso(mosi),   // Outputul modulului trimite date pe pinul 'mosi'
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out)
    );

    // 2. INSTRUCTION DECODER
    // Interpreteaza comenzile primite prin SPI
    instr_dcd i_instr_dcd (
        .clk(clk),
        .rst_n(rst_n),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write)
    );

    // 3. REGISTER FILE
    // Stocheaza configuratiile
    regs i_regs (
        .clk(clk),
        .rst_n(rst_n),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write),
        .counter_val(counter_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale),
        .pwm_en(pwm_en),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2)
    );

    // 4. COUNTER
    // Genereaza baza de timp
    counter i_counter (
        .clk(clk),
        .rst_n(rst_n),
        .count_val(counter_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale)
    );

    // 5. PWM GENERATOR
    // Compara contorul cu pragurile pentru a genera semnalul
    pwm_gen i_pwm_gen (
        .clk(clk),
        .rst_n(rst_n),
        .pwm_en(pwm_en),
        .period(period),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2),
        .count_val(counter_val),
        .pwm_out(pwm_out)
    );

endmodule