# MacViKey - test engine. Khong can Xcode, khong can macOS API.
CXX      ?= clang++
CXXFLAGS ?= -std=c++14 -O1 -Wall -Wno-unused-variable -Wno-deprecated-declarations
ENGINE   := ../engine
SRC      := $(ENGINE)/Engine.cpp $(ENGINE)/Vietnamese.cpp \
            $(ENGINE)/SmartSwitchKey.cpp

test: build
	@./test_engine

build:
	@$(CXX) $(CXXFLAGS) -o test_engine test_engine.cpp $(SRC)

clean:
	@rm -f test_engine

.PHONY: test build clean
