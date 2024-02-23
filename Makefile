SWIFTC=swiftc
HEADER_PATH=
OUT_LIB=libswift.dylib
SWIFT_SRC=PlatformLib.swift
C_HEADERS=InteropStructs.h
FLAGS=-import-objc-header $(C_HEADERS) -emit-library

all: $(OUT_LIB)

$(OUT_LIB): $(SWIFT_SRC) $(C_HEADERS)
	$(SWIFTC) $(FLAGS) -o $@ $(SWIFT_SRC)

clean:
	rm -f $(OUT_LIB)