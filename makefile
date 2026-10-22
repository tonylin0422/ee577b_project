# Cadence NCSIM verification. Source the course tool environment first.
# make                         Elaborate NIC, router, and mesh
# make -j3 sim                 Run all three simulations concurrently
# make sim-nic / sim-router / sim-mesh     Run one simulation
# make simg-nic / simg-router / simg-mesh  Open one simulation in the GUI
# make SIM=nic sim             Select a default simulation
# make sim-mesh SIM_ARGS='+SCENARIO=latency +WAVES'
# Outputs (libraries, logs, waves, CSVs) live in work/<simulation>/.
# router tests a standalone router; mesh tests the full 4x4 network.

.DEFAULT_GOAL := all
SIM ?= all
SIMULATIONS := nic router mesh
ifeq ($(filter $(SIM),all $(SIMULATIONS)),)
$(error SIM must be all, nic, router, or mesh)
endif
SELECTED := $(if $(filter all,$(SIM)),$(SIMULATIONS),$(SIM))
ROOT := $(CURDIR)
TOP_nic := tb_cardinal_nic
TOP_router := tb_cardinal_router
TOP_mesh := tb_gold_mesh_4x4
DESIGN_nic := $(ROOT)/design/cardinal_nic.v
DESIGN_router := $(addprefix $(ROOT)/design/,input_controller.v output_controller.v cardinal_router.v)
DESIGN_mesh := $(DESIGN_router) $(ROOT)/design/gold_mesh_4x4.v
TB_nic := $(ROOT)/tb/tb_cardinal_nic.v
TB_router := $(ROOT)/tb/tb_cardinal_router.v
TB_mesh := $(ROOT)/tb/tb_gold_mesh_4x4.v
INCLUDE_DIRECTORY := $(ROOT)/include
INCLUDE_FILES := $(wildcard include/*)
SIM_SCRIPT_FILE_GUI := $(ROOT)/scripts/runscript.tcl
SIM_SCRIPT_FILE_NO_GUI := $(ROOT)/scripts/runscript_nogui.tcl
SIM_ARGS ?=
NCVLOG ?= ncvlog
NCELAB ?= ncelab
NCSIM ?= ncsim

# ncvlog switch 
NCVLOG_SWITCHES = \
	-STATUS \
	-MESSAGES \
	-UPDATE \
	-INCDIR $(INCLUDE_DIRECTORY)

#ncelab switches
NCELAB_SWITCHES = \
	-ACCESS +rwc \
	-NCFATAL INVSUP \
	-NCFATAL CUNOTB \
	-ERRORMAX 5 \
	-UPDATE \
	-MESSAGES \
	-TIMESCALE '1ns/10ps' \
	-LIBVERBOSE

# ncsim simulation switches for console simulation
NCSIM_SWITCHES_NO_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_NO_GUI)

# ncsim switches for GUI simulations
NCSIM_SWITCHES_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_GUI) \
	-GUI


.PHONY: all sim simg clean dir
all: $(addprefix elab-,$(SELECTED))
sim: $(addprefix sim-,$(SELECTED))
simg: $(addprefix simg-,$(SELECTED))

# Separate working directories isolate Cadence libraries and testbench output.
# Fail immediately on a compiler error; only successful builds get a stamp.
define SIM_RULES
.PHONY: elab-$(1) sim-$(1) simg-$(1) clean-$(1)
elab-$(1): work/$(1)/elab.stamp

work/$(1)/ana.stamp: $$(DESIGN_$(1)) $$(TB_$(1)) $$(INCLUDE_FILES) makefile
	@mkdir -p work/$(1)/work
	@printf 'DEFINE work work\n' > work/$(1)/cds.lib
	@printf '# Cadence library configuration\n' > work/$(1)/hdl.var
	@rm -f $$@ work/$(1)/elab.stamp
	cd work/$(1) && $$(NCVLOG) $$(NCVLOG_SWITCHES) -work work $$(DESIGN_$(1)) $$(TB_$(1))
	@touch $$@

work/$(1)/elab.stamp: work/$(1)/ana.stamp
	@rm -f $$@
	cd work/$(1) && $$(NCELAB) $$(NCELAB_SWITCHES) work.$$(TOP_$(1))
	@touch $$@

sim-$(1): work/$(1)/elab.stamp
	@cd work/$(1) && $$(NCSIM) $$(NCSIM_SWITCHES_NO_GUI) work.$$(TOP_$(1)) $$(SIM_ARGS) > sim.log 2>&1; status=$$$$?; cat sim.log; test $$$$status -eq 0
	@grep -Eq '^PASS[[:space:]]' work/$(1)/sim.log && ! grep -Eq '^FAIL([[:space:]]|$$$$)' work/$(1)/sim.log || { echo 'Simulation $(1) failed or did not report PASS'; exit 1; }

simg-$(1): work/$(1)/elab.stamp
	cd work/$(1) && $$(NCSIM) $$(NCSIM_SWITCHES_GUI) work.$$(TOP_$(1)) $$(SIM_ARGS)

clean-$(1):
	rm -rf work/$(1)
endef
$(foreach simulation,$(SIMULATIONS),$(eval $(call SIM_RULES,$(simulation))))

clean: $(addprefix clean-,$(SIMULATIONS))

dir:
	@mkdir -p work design tb include scripts etc
