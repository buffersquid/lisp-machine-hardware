CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -pedantic -Werror
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
OUTDIR = bin

TARGET = mem_gen
SRC = src/*

all: $(OUTDIR)/$(TARGET)

$(OUTDIR)/$(TARGET): $(SRC)
	mkdir -p $(OUTDIR)
	$(CC) $(CFLAGS) -o $@ $^

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(OUTDIR)$(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

clean:
	rm -f $(OUTDIR)/$(TARGET)
