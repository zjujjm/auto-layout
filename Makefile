#**
# @file Makefile
# @brief 
# @author Junmin JIANG
# @version v1
# @date 2014-10-01
# 
# 28, Jan, 2015
# v2: link library is added
# 
# 10, Arp, 2015
# Restruct the dictories, add bash script to handle sub task
#
# --- Load configuration file --
include ./config
include ./default/config.default

# --- Variable definition --
TOP_MODULE = default
CURRENT_PATH = `pwd`
RVE_FILE = ''
FCMD = "AL: from CMD ->| "

# --- Command Start --
all: drc-all lvs-all

# --- Reset --
# --- Display status --
status:
	@echo $(FCMD)"Current PATH is:" $(CURRENT_PATH)
	@echo $(FCMD)"Module under processing:" $(TOP_MODULE)

# --- Link library --
init: status
	@./default/bin/init.sh -p $(LIBRARY_PATH) -l $(LIBRARY_NAME)

# --- Set RVE enviroment --
link-rve:
	@echo "Link RVE configure file to " $(RVE_SETUP_FILE)
	@rm ~/.rvedb -f
	@ln -s $(CURRENT_PATH)/default/$(RVE_SETUP_FILE) ~/.rvedb 
	@if [ -a ~/.rvedb ]; then echo "Link successfully."; fi;

set-rve-dir:
	@setenv MGC_CALIBRE_DB_DIR $(CURRENT_PATH)

run-rve-drc: link-rve
	@./default/bin/runRVE.sh -m $(TOP_MODULE) -t drc

run-rve-lvs: link-rve
	@./default/bin/runRVE.sh -m $(TOP_MODULE) -t lvs

# In sed, when using a dirctory as a deried string, use ':' instead of '/'
set-streamout-template:
	@echo "Copy new setup file for streamout"
	@./default/bin/buildRule.sh -m $(TOP_MODULE) -t GDS -c "GDSOUT_ERR_FILE=$(GDSOUT_ERR_FILE) \
		GDSOUT_FILE=$(GDSOUT_FILE) \
		TOP_MODULE=$(TOP_MODULE) \
		LIBRARY_NAME=$(LIBRARY_NAME) \
		GDSRUN_DIR=$(GDSRUN_DIR)"
	@pipo2Xstrm.pl -in $(GDSRUN_DIR)/$(TOP_MODULE).streamout.setup -out $(GDSRUN_DIR)/$(TOP_MODULE).streamout.template -log $(GDSRUN_DIR)/$(TOP_MODULE).pipo2Xstrm.log -overwrite
	@echo "Stream out setup finished" 
# For IC 5141, the command is pipo strmout
# For IC 615, the command is only strmout
streamout-gds: set-streamout-template
	@echo "Stream out GDS file"
	@if [ $(ISIC615) -eq 1 ]; then\
		if [ -a $(GDSRUN_DIR)/$(TOP_MODULE).streamout.template ]; then\
		    cd library;\
		    strmout -templateFile $(GDSRUN_DIR)/$(TOP_MODULE).streamout.template;\
		fi;\
	 else\
	    if [ -a $(GDSRUN_DIR)/$(TOP_MODULE).streamout.setup ]; then\
		    cd library;\
		    pipo strmout $(GDSRUN_DIR)/$(TOP_MODULE).streamout.setup;\
		fi;\
	 fi;
	@echo "Stream out GDS file successfully"

# Setting file is si.env
set-cdl-template:
	@echo "Stream out CDL file"
	@./default/bin/buildRule.sh -m $(TOP_MODULE) -t CDL -c "\
		LIBRARY_NAME=$(LIBRARY_NAME) \
	    TOP_MODULE=$(TOP_MODULE) \
		CDLOUT_FILE=$(TOP_MODULE).cdl"	

export-cdl: set-cdl-template
	@cd library;\
		si $(CDL_DIR) -batch -command netlist

lvs-preparation: streamout-gds export-cdl

# DRC rule generation 

RULE_NUMBER = `grep 'DRC_RULE' config -c`
LINE = `cat $(AL_ROOT_DIR)/config | grep "DRC_RULE"` 
DRC_F1=`echo $$DRC_ | cut -d "=" -f1`
DRC_F2=`echo $$DRC_ | cut -d "=" -f2`
calc-rule-number:
	@for DRC_ in $(LINE) ;\
		do\
		echo $(DRC_F1) $(DRC_F2);\
		done
	@echo "Number of rules is" $(RULE_NUMBER)

build-drc-rule:  
	@echo "Building DRC rule"
	@echo "Building rule file 1"
	@echo "Number of rules is" $(RULE_NUMBER)
	@for DRC_ in $(LINE) ;\
		do\
		echo "Building:" $(DRC_F1);\
	    echo "INCLUDE" $(DRC_F2) >> $(DRC_RESULT_DIR)/$(TOP_MODULE).$(DRC_F1).drc.rul;\
	    ./default/bin/buildRule.sh -m $(TOP_MODULE) -t drc -r $(DRC_F1) -c "\
		TOP_MODULE=$(TOP_MODULE) \
	    TOP_MODULE_NAME=$(TOP_MODULE) \
		GDSOUT_FILE=$(GDSOUT_FILE) \
		RULE_NAME=$(DRC_F1) \
	    DRC_RULE_PATH=$(DRC_F2)"	;\
		done
	@echo "DRC rule built"

build-lvs-rule:
	@echo "Building LVS rule"
	@touch $(LVS_RESULT_DIR)/$(TOP_MODULE).sch.net
	@echo " " > $(LVS_RESULT_DIR)/$(TOP_MODULE).sch.net
	@echo ".INCLUDE" \"$(CDL_DIR)/$(TOP_MODULE).cdl\" >> $(LVS_RESULT_DIR)/$(TOP_MODULE).sch.net
	@echo ".INCLUDE" \"$(CDL_INCLUDE)\" >> $(LVS_RESULT_DIR)/$(TOP_MODULE).sch.net
	@./default/bin/buildRule.sh -m $(TOP_MODULE) -t lvs -c "\
		GDSOUT_FILE=$(GDSOUT_FILE) \
	    TOP_MODULE=$(TOP_MODULE) \
		LVS_RULE=$(LVS_RULE) \
		LVS_SOURCE_NET=$(TOP_MODULE).sch.net \
		LVS_SOURCE_MODULE=$(TOP_MODULE)"
	@echo "LVS rule built"

run-lvs: streamout-gds export-cdl build-lvs-rule
	cd $(LVS_RESULT_DIR) ;\
		calibre -lvs -spice $(TOP_MODULE).lay.net -hier -turbo -nowait $(TOP_MODULE).lvs.rul > $(TOP_MODULE).lvs.log

run-drc: streamout-gds build-drc-rule
	@cd $(DRC_RESULT_DIR) ;\
	    for DRC_ in $(LINE) ;\
		do\
		    echo "Running DRC:" $$DRC_;\
		    calibre -drc -hier -turbo -turbo_litho -nowait $(TOP_MODULE).$(DRC_F1).drc.rul \
			> $(TOP_MODULE).$(DRC_F1).drc.log ;\
		done;\

drc-all: run-drc run-rve-drc 

lvs-all: run-lvs run-rve-lvs 

clean:
	rm *.log *.setup -f
	rm result/drcresult/* -rf
	rm result/lvsresult/* -rf
	rm result/ercresult/* -rf
	rm CDL/* -rf
	rm GDS/* -rf

reset:
	rm ./library/*
