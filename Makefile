PROJECT := vertlover
JUNGLE := monkey.jungle
MANIFEST := manifest.xml
RESOURCES := $(shell find -L resources* -name '*.xml')
SOURCES := $(shell find -L source -name '*.mc')

CIQ_DEBUG ?= 0
OUTPUT_BASE := ./bin/$(PROJECT)
OUTPUT_RELEASE := ./bin/$(PROJECT).iq
RELEASE_FLAG := -r
TYPE_CHECK := -l0

ifneq ($(CIQ_DEBUG), 0)
	OUTPUT_BASE := $(OUTPUT_BASE).debug
	RELEASE_FLAG :=
endif

OUTPUT := $(OUTPUT_BASE).prg

.PHONY: help
help:
	@echo 'Make targets:'
	@echo '  build - build binary for a specific device'
	@echo '  iq    - package the data screen for the app store'
	@echo '  run   - launch in simulator'
	@echo '  clean - delete all build output'

dev_prereqs:
ifndef CIQ_DEVKEY
	$(error CIQ_DEVKEY not set)
endif
	mkdir -p bin

build_prereqs: dev_prereqs
ifndef CIQ_DEVICE
	$(error CIQ_DEVICE not set)
endif

${OUTPUT}: $(MANIFEST) $(RESOURCES) $(SOURCES) build_prereqs
	monkeyc -w $(TYPE_CHECK) $(RELEASE_FLAG) -o $@ -d $(CIQ_DEVICE) -y $(CIQ_DEVKEY) -f $(JUNGLE)

build: $(OUTPUT)

run: $(OUTPUT)
	connectiq && sleep 1
	monkeydo $(OUTPUT) $(CIQ_DEVICE)

${OUTPUT_RELEASE}: $(MANIFEST) $(RESOURCES) $(SOURCES) dev_prereqs
	monkeyc -e -w $(TYPE_CHECK) -r -o $@ -y $(CIQ_DEVKEY) -f $(JUNGLE)

iq: $(OUTPUT_RELEASE)

clean:
	rm -rf bin

