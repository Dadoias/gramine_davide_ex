CFLAGS = -Wall -Wextra

ifeq ($(DEBUG),1)
GRAMINE_LOG_LEVEL = debug
CFLAGS += -g
else
GRAMINE_LOG_LEVEL = error
CFLAGS += -O3
endif

.PHONY: all
all: somma somma.manifest
ifeq ($(SGX),1)
all: somma.manifest.sgx somma.sig somma.token
endif

somma: somma.o

somma.o: somma.c

somma.manifest: somma.manifest.template
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		$< $@

somma.sig somma.manifest.sgx: sgx_sign
	@:

.INTERMEDIATE: sgx_sign
sgx_sign: somma.manifest somma
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx

somma.token: somma.sig
	gramine-sgx-get-token \
		--output $@ --sig $<

ifeq ($(SGX),)
GRAMINE = gramine-direct
else
GRAMINE = gramine-sgx
endif

.PHONY: check
check: all
	$(GRAMINE) somma > OUTPUT
	echo "Hello World" | diff OUTPUT -
	@echo "[ Success ]"

.PHONY: clean
clean:
	$(RM) *.token *.sig *.manifest.sgx *.manifest somma.o somma OUTPUT

.PHONY: distclean
distclean: clean
