# Include configuration file
include ./config/configuration.cfg

# --------------------------------
# File discovery
# --------------------------------
VHDL_ALL := $(shell find $(SRCDIR) $(TBDIR) -type f \( \
	-name "*.vhd" -o -name "*.vhdl" -o -name "*.vhf" \))

VERILOG_ALL := $(shell find $(SRCDIR) $(TBDIR) -type f \( \
	-name "*.v" -o -name "*.vh" -o -name "*.sv" -o -name "*.svh" \))

VHDL_SRC := $(shell find $(SRCDIR) -type f \( \
	-name "*.vhd" -o -name "*.vhdl" -o -name "*.vhf" \))

VERILOG_SRC := $(shell find $(SRCDIR) -type f \( \
	-name "*.v" -o -name "*.vh" -o -name "*.sv" -o -name "*.svh" \))


# --------------------------------
# Reusable Simulation Rules
# --------------------------------
# Prepare ModelSim environment
prepare_simulation :
	@echo "Creating ModelSim library..."
	$(SIMULATOR)vlib $(GENERATED)ModelSim
	$(SIMULATOR)vmap work $(GENERATED)ModelSim && rm ./modelsim.ini

# Compile VHDL files
compile_vhdl :
	@echo "Compiling VHDL..."
	$(foreach file, $(VHDL_ALL), $(SIMULATOR)vcom -2008 -work work $(file);) \

# Compile Verilog/SystemVerilog files
compile_verilog :
	@echo "Compiling Verilog/SystemVerilog..."; \
	$(foreach file, $(VERILOG_ALL), $(SIMULATOR)vlog -sv -work work $(file);) \

# Compile VHDL files
compile_vhdl_src :
	@echo "Compiling VHDL..."
	$(foreach file, $(VHDL_SRC), $(SIMULATOR)vcom -2008 -work work $(file);) \

# Compile Verilog/SystemVerilog files
compile_verilog_src :
	@echo "Compiling Verilog/SystemVerilog..."; \
	$(foreach file, $(VERILOG_SRC), $(SIMULATOR)vlog -sv -work work $(file);) \

# --------------------------------
# Targets
# --------------------------------

# Run predefined testbench (TOP_TB)
run_tb : prepare_simulation compile_vhdl compile_verilog
	@echo "Running predefined testbench $(TOP_TB)..."
	$(SIMULATOR)vsim $(SIM_TB_FLAGS) work.$(TOP_TB) -do "run -all; quit"

# Simulate and let user specify the testbench (can override TOP_TB)
simulate : prepare_simulation compile_vhdl_src compile_verilog_src
	@echo "Simulating with testbench $(TOP_TB)..."
	$(SIMULATOR)vsim $(SIM_WAVE_FLAGS) work.$(TOP) && mv ./transcript $(GENERATED)ModelSim/transcript
	mv ./vsim.wlf $(SIM_OUTPUT)$(PROJNAME).wlf



# --------------------------------
# Synthesis
# --------------------------------
synthesize : project_constraints
	@echo "Synthesizing design..."
	@if [ "$(TOOLCHAIN)" = "QUARTUS13" ]; then \
		$(QUARTUS13)quartus_map $(GENERATED)$(PROJNAME) \
			--parallel=$$(nproc) --64bit --effort=auto --family=$(BOARD_FAMILY) \
			--incremental_compilation=full_incremental_compilation \
			--optimize=balanced --part=$(CHIP_PART_NUMBER) \
			--state_machine_encoding=auto > $(LOGDIR)synthesis.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "QUARTUS23" ]; then \
		$(QUARTUS23)quartus_map $(GENERATED)$(PROJNAME) \
			--parallel=$$(nproc) --64bit --effort=auto --family=$(BOARD_FAMILY) \
			--incremental_compilation=full_incremental_compilation \
			--optimize=balanced --part=$(CHIP_PART_NUMBER) \
			--state_machine_encoding=auto > $(LOGDIR)synthesis.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "VIVADO24" ]; then \
		echo "Synthesis for Vivado not implemented yet"; \
	else \
		echo "ERROR: TOOLCHAIN $$TOOLCHAIN not supported"; exit 1; \
	fi
	@echo "Synthesis completed. Log: $(LOGDIR)synthesis.log"

# --------------------------------
# Place and Route
# --------------------------------
placeANDroute : synthesize
	@echo "Running place and route..."
	@if [ "$(TOOLCHAIN)" = "QUARTUS13" ]; then \
		$(QUARTUS13)quartus_fit $(GENERATED)$(PROJNAME) \
			--64bit --part=$(CHIP_PART_NUMBER) --parallel=$$(nproc) --effort=standard \
			--seed=$(SEED) --optimize_io_register_for_timing=off \
			--pack_register=normal > $(LOGDIR)pnr.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "QUARTUS23" ]; then \
		$(QUARTUS23)quartus_fit $(GENERATED)$(PROJNAME) \
			--64bit --part=$(CHIP_PART_NUMBER) --parallel=$$(nproc) --effort=standard \
			--seed=$(SEED) --optimize_io_register_for_timing=off \
			--pack_register=normal > $(LOGDIR)pnr.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "VIVADO24" ]; then \
		echo "Place & Route for Vivado not implemented"; \
	else \
		echo "ERROR: TOOLCHAIN $$TOOLCHAIN not supported"; exit 1; \
	fi
	@echo "Place and route completed. Log: $(LOGDIR)pnr.log"


# --------------------------------
# Bitstream
# --------------------------------
bitstream : placeANDroute
	@echo "Creating the bitstream..."
	@if [ "$(TOOLCHAIN)" = "QUARTUS13" ]; then \
		$(QUARTUS13)quartus_asm $(GENERATED)$(PROJNAME) --64bit > $(LOGDIR)bitstream.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "QUARTUS23" ]; then \
		$(QUARTUS23)quartus_asm $(GENERATED)$(PROJNAME) --64bit > $(LOGDIR)bitstream.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "VIVADO24" ]; then \
		echo "Bitstream generation for Vivado not implemented"; \
	else \
		echo "ERROR: TOOLCHAIN $$TOOLCHAIN not supported"; exit 1; \
	fi
	@echo "Bitstream completed. Log: $(LOGDIR)bitstream.log"
	
# --------------------------------
# Programming
# --------------------------------
program : bitstream
	@echo "Programming FPGA with $(TOOLCHAIN)..."
	@if [ "$(TOOLCHAIN)" = "QUARTUS13" ]; then \
		cp $(GENERATED)$(PROJNAME).*of $(BINDIR) && \
		$(QUARTUS13)quartus_pgm -m jtag -o "p;$(BINDIR)$(PROJNAME).sof" > $(LOGDIR)programmer.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "QUARTUS23" ]; then \
		cp $(GENERATED)$(PROJNAME).*of $(BINDIR) && \
		$(QUARTUS23)quartus_pgm -m jtag -o "p;$(BINDIR)$(PROJNAME).sof" > $(LOGDIR)programmer.log 2>&1; \
	elif [ "$(TOOLCHAIN)" = "VIVADO24" ]; then \
		echo "Programming for Vivado not implemented"; \
	else \
		echo "ERROR: TOOLCHAIN $$TOOLCHAIN not supported"; exit 1; \
	fi
	@echo "Programming completed. Log: $(LOGDIR)/programmer.log"

# --------------------------------
# Project synth requirements
# --------------------------------
project_constraints :
	@echo "Creating synth requirements..."
	@if [ "$(TOOLCHAIN)" = "QUARTUS13" ]; then \
		mkdir -p "$(GENERATED)"; \
		echo "Creating new QPF file for $(TOOLCHAIN)"; \
		echo "QUARTUS_VERSION = \"13.0 SP1\"" > "$(GENERATED)$(PROJNAME).qpf"; \
		echo "DATE = \"`date '+%H:%M:%S %B %d, %Y'`\"" >> "$(GENERATED)$(PROJNAME).qpf"; \
		echo "PROJECT_REVISION = \"$(PROJNAME)\"" >> "$(GENERATED)$(PROJNAME).qpf"; \
		echo "Created $(GENERATED)$(PROJNAME).qpf"; \
		\
		echo "Generating QSF file..."; \
		echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP)" > "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name LAST_QUARTUS_VERSION \"13.0 SP1\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name FAMILY \"$(BOARD_FAMILY)\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE $(CHIP_PART_NUMBER)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_IO_STANDARD \"3.3-V LVTTL\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION \"USE AS REGULAR IO\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION \"USE AS REGULAR IO\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_PACKAGE TQFP" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_PIN_COUNT $(PIN_COUNT)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_SPEED_GRADE $(SPEED_GRADE)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name AUTO_PACKED_REGISTERS_STRATIXII NORMAL" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name OPTIMIZE_IOC_REGISTER_PLACEMENT_FOR_TIMING OFF" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name SEED $(SEED)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name FITTER_EFFORT \"STANDARD FIT\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name RESERVE_ALL_UNUSED_PINS \"AS INPUT TRI-STATED WITH WEAK PULL-UP\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		\
		for file in $(VHDL_SRC); do \
			echo "set_global_assignment -name VHDL_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf"; \
		done; \
		for file in $(VERILOG_SRC); do \
			case "$$file" in \
				*.sv|*.svh) echo "set_global_assignment -name SYSTEMVERILOG_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf" ;; \
				*) echo "set_global_assignment -name VERILOG_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf" ;; \
			esac; \
		done; \
		\
		if [ -f "$(CONSTRAINTDIR)IOAssignments.pins" ]; then \
			while IFS= read -r line; do \
				line=$$(echo "$$line" | sed 's/#.*//'); \
				line=$$(echo "$$line" | xargs); \
				[ -z "$$line" ] && continue; \
				set -- $$line; \
				pin=$$1; \
				signal=$$2; \
				echo "set_location_assignment $$pin -to $$signal" >> "$(GENERATED)$(PROJNAME).qsf"; \
				echo "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to $$signal" >> "$(GENERATED)$(PROJNAME).qsf"; \
			done < "$(CONSTRAINTDIR)IOAssignments.pins"; \
		fi; \
		echo "QSF generation complete."; \
	elif [ "$(TOOLCHAIN)" = "QUARTUS23" ]; then \
		mkdir -p "$(GENERATED)"; \
		echo "Creating new QPF file for $(TOOLCHAIN)"; \
		echo "QUARTUS_VERSION = \"23.1\"" > "$(GENERATED)$(PROJNAME).qpf"; \
		echo "DATE = \"`date '+%H:%M:%S %B %d, %Y'`\"" >> "$(GENERATED)$(PROJNAME).qpf"; \
		echo "PROJECT_REVISION = \"$(PROJNAME)\"" >> "$(GENERATED)$(PROJNAME).qpf"; \
		echo "Created $(GENERATED)$(PROJNAME).qpf"; \
		\
		echo "Generating QSF file..."; \
		echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP)" > "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name LAST_QUARTUS_VERSION \"23.1 STD\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name FAMILY \"$(BOARD_FAMILY)\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE $(CHIP_PART_NUMBER)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_IO_STANDARD \"3.3-V LVTTL\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION \"USE AS REGULAR IO\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION \"USE AS REGULAR IO\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_PACKAGE TQFP" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_PIN_COUNT $(PIN_COUNT)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name DEVICE_FILTER_SPEED_GRADE $(SPEED_GRADE)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name AUTO_PACKED_REGISTERS_STRATIXII NORMAL" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name OPTIMIZE_IOC_REGISTER_PLACEMENT_FOR_TIMING OFF" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name SEED $(SEED)" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name FITTER_EFFORT \"STANDARD FIT\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		echo "set_global_assignment -name RESERVE_ALL_UNUSED_PINS \"AS INPUT TRI-STATED WITH WEAK PULL-UP\"" >> "$(GENERATED)$(PROJNAME).qsf"; \
		for file in $(VHDL_SRC); do \
			echo "set_global_assignment -name VHDL_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf"; \
		done; \
		for file in $(VERILOG_SRC); do \
			case "$$file" in \
				*.sv|*.svh) echo "set_global_assignment -name SYSTEMVERILOG_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf" ;; \
				*) echo "set_global_assignment -name VERILOG_FILE .$$file" >> "$(GENERATED)$(PROJNAME).qsf" ;; \
			esac; \
		done; \
		if [ -f "$(CONSTRAINTDIR)IOAssignments.pins" ]; then \
			while IFS= read -r line; do \
				line=$$(echo "$$line" | sed 's/#.*//'); \
				line=$$(echo "$$line" | xargs); \
				[ -z "$$line" ] && continue; \
				set -- $$line; \
				pin=$$1; \
				signal=$$2; \
				echo "set_location_assignment $$pin -to $$signal" >> "$(GENERATED)$(PROJNAME).qsf"; \
				echo "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to $$signal" >> "$(GENERATED)$(PROJNAME).qsf"; \
			done < "$(CONSTRAINTDIR)IOAssignments.pins"; \
		fi; \
		echo "QSF generation complete."; \
	elif [ "$(TOOLCHAIN)" = "VIVADO24" ]; then \
		echo "Vivado flow not implemented yet"; \
	else \
		echo "ERROR: TOOLCHAIN $$TOOLCHAIN not supported"; exit 1; \
	fi
	@echo "Created synth requirements. Log: $(LOGDIR)created_synth_requirements.log"
# --------------------------------
# Override the default TOP_TB for manual control
# Example: `make simulate TOP_TB=MyManualTestbench`
TOP_TB ?= $(TOP)
