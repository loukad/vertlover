PROJECT := vertlover
JUNGLE := monkey.jungle
MANIFEST := manifest.xml
RESOURCES := $(shell find -L resources* -name '*.xml')
SOURCES := $(shell find -L source -name '*.mc')

CIQ_DEBUG ?= 0
OUTPUT_BASE := ./bin/$(PROJECT)
RELEASE_FLAG := -r

ifneq ($(CIQ_DEBUG), 0)
	OUTPUT_BASE := $(OUTPUT_BASE).debug
	RELEASE_FLAG :=
endif

OUTPUT := $(OUTPUT_BASE).prg

.PHONY: help
help:
	@echo 'Make targets:'
	@echo '  build	- build with debug info'
	@echo '  iq     - package the data screen for the app store'
	@echo '  run	- launch in simulator'
	@echo '  clean	- delete all build output'

build_prereqs:
ifndef CIQ_DEVICE
	$(error CIQ_DEVICE not set)
endif

ifndef CIQ_DEVKEY
	$(error CIQ_DEVKEY not set)
endif
	mkdir -p bin

${OUTPUT}: $(MANIFEST) $(RESOURCES) $(SOURCES) build_prereqs
	monkeyc -w $(RELEASE_FLAG) -o $@ -d $(CIQ_DEVICE) -y $(CIQ_DEVKEY) -f $(JUNGLE)

build: $(OUTPUT)

run: $(OUTPUT)
	connectiq && sleep 1
	monkeydo $(OUTPUT) $(CIQ_DEVICE)

