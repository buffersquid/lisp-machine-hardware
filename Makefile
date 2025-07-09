VIVADO_BIN     := /opt/Xilinx/2025.1/Vivado/bin/vivado
VIVADO_FLAGS   := -nolog -nojournal
VIVADO_DIR     := vivado
SRC_DIR        := src
CONSTR_DIR     := constr
CORES          := $(shell nproc)
TOP            := core

BUILD_DIR      := build
BIT_FILE       := $(BUILD_DIR)/$(TOP).bit

# Create project and build bitstream
$(BIT_FILE): 
	$(VIVADO_BIN) -mode batch $(VIVADO_FLAGS) -source $(VIVADO_DIR)/create_project.tcl -tclargs $(TOP) $(CORES)

program_fpga: $(BIT_FILE)
	$(VIVADO_BIN) -mode batch $(VIVADO_FLAGS) -source $(VIVADO_DIR)/program_fpga.tcl -tclargs $(TOP)

clean:
	rm -rf build/ *.jou *.log vivado/.Xil vivado/*.log vivado/*.jou
