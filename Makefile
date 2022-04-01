# Detect underlying system.
ifeq ($(OS),Windows_NT)
	detected_OS := Windows
else
	detected_OS := $(shell sh -c 'uname -s 2>/dev/null || echo not')
endif

export detected_OS
# Set default C compiler.
# Clean implict CC variable.
CC=

ifndef CC
	ifeq ($(detected_OS),Windows)
		CC=cl
	else ifeq ($(detected_OS),Darwin)
		CC=clang
	else
		CC=gcc
	endif
endif  # CC

export CC

# Clean C_STD variable.
C_STD=

ifndef C_STD
	ifeq ($(CC),cl)
		C_STD=
	else
		C_STD=c1z
	endif
endif  # C_STD

export C_STD

# Set CFLAGS for Release target.
CFLAGS=
ifndef CFLAGS
	ifeq ($(CC),cl)
		CFLAGS=/W4 /sdl
	else
		CFLAGS:=-Wall -Wextra -std=$(C_STD)
	endif
endif

# Set CFLAGS for Debug target.
ifneq (,$(DEBUG))
	ifeq ($(CC),cl)
		CFLAGS+=/DDEBUG /Zi /Od
	else
		CFLAGS+=-DDEBUG -g -O0
	endif
else
	ifeq ($(CC),cl)
		CFLAGS+=/O2
	else
		CFLAGS+=-O2
	endif
endif

export CFLAGS

# Set proper RM on Windows.
ifeq ($(detected_OS),Windows)
	RM=del /q /f
endif

export RM

# Set proper path separator.
ifeq ($(detected_OS),Windows)
	SEP=\\
else
	SEP=/
endif

export SEP

# Set proper program name.
ifeq ($(detected_OS),Windows)
	PROGRAM=my_app.exe
else
	PROGRAM=my_app
endif

export PROGRAM

# Add your own test programs as needed.
ifeq ($(detected_OS),Windows)
	TEST_PROGRAM=my_app.vbs
else
	TEST_PROGRAM=my_app.bash
endif

# Modify it if more than one source files.
SOURCE=$(PROGRAM:.exe=).cpp

# Set object files.
ifeq ($(CC),cl)
	OBJS=$(SOURCE:.cpp=.obj)
else
	OBJS=$(SOURCE:.cpp=.o)
endif  # OBJS

export OBJS

# Set third-party include and library path
# Modify it as needed.
ifeq ($(CC),cl)
	LDFLAGS=
	LDLIBS=
else
	LDFLAGS=
	LDLIBS=
endif

export LDFLAGS
export LDLIBS


.PHONY: all clean

all: run

test: $(PROGRAM)
ifeq ($(detected_OS),Windows)
	for %%x in ($(TEST_PROGRAM)) do cscript %%x
else
	for t in $(TEST_PROGRAM); do bats $$t; done
endif

run: $(PROGRAM)
	.$(SEP)$(PROGRAM)
	echo $$?

$(PROGRAM): $(OBJS)
ifeq ($(CC),cl)
	$(CC) /Fe:$(PROGRAM) $(OBJS) $(CFLAGS) $(LDFLAGS) $(LDLIBS)
else
	@echo ">>> obj:$(OBJS)"
	$(CC) -o $(PROGRAM) $(OBJS) $(CFLAGS) $(LDFLAGS) $(LDLIBS)
endif

%.obj: %.cpp
	$(CC) /c $< $(CFLAGS)

%.o: %.cpp
	$(CC) -c $< $(CFLAGS)

clean:
	$(RM) $(PROGRAM) $(OBJS)
