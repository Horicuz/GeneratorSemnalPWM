# =============================================================
# Makefile for PWM Generator Project (top + all submodules)
# =============================================================

# -------------- CONFIG -----------------
TOP        = top
TB         = tb_top
OUTPUT     = sim_top
VCD        = top.vcd

IVERILOG   = iverilog
VVP        = vvp
GTK        = gtkwave

# -------------- SOURCES -----------------
SRCS = \
    Counter/counter.v \
    Decodor/instr_dcd.v \
    PWM_GEN/pwm_gen.v \
    Regs/regs.v \
    Spi_Bridge/spi_bridge.v \
    top.v \
    tb_top.v

# -------------- BUILD -------------------
all: run

compile:
	$(IVERILOG) -o $(OUTPUT) $(SRCS)

run: compile
	$(VVP) $(OUTPUT)

waves:
	$(GTK) $(VCD) &

clean:
	rm -f $(OUTPUT) $(VCD)
