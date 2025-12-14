# =============================================================
# Makefile for PWM Generator System (top + all modules)
# =============================================================

# -------------- CONFIG -----------------
TOP      = top
TB       = testbench

OUTPUT   = sim_top
VCD      = waves.vcd

IVERILOG = iverilog
VVP      = vvp
GTK      = gtkwave

# -------------- SOURCES -----------------
SRCS = \
    counter.v \
    instr_dcd.v \
    pwm_gen.v \
    regs.v \
    spi_bridge.v \
    top.v \
    testbench.v

# -------------- BUILD & RUN -------------
all: run

compile:
	$(IVERILOG) -g2012 -o $(OUTPUT) $(SRCS)

run: compile
	$(VVP) $(OUTPUT)

waves:
	$(GTK) $(VCD) &

clean:
	rm -f $(OUTPUT) $(VCD)