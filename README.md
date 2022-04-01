# 关于GNU Make的跨平台Makefile
通常一个高效的项目都会提供跨平台可移植运行的解决方案，但对跨平台运行的技术挑战不小，也有两种方案：一种是虚拟机宿主程序，可以运行于各大主流操作系统；另一种是通过编译出各大操作系统可运行的程序，直接在对应的系统运行。下面就对后一种方法进行介绍。

## 各操作系统依赖的编译工具

* Windows：使用Visual C++,但保留使用MinGW(GCC)的弹性；
* MAC：使用Clang,但保留使用GCC的弹性；
* GNU/Linux：使用GCC，但保留使用Clang的弹性；

考虑到系统市场市占率，推荐使用Makefile + GCC的方案。


## 如何跨平台兼容各大OS

### 侦测编译时的OS

目前主流的平台中，除Windows系统以外，都是类Unix系统，通常可以通过uname命令获取系统名称。

```Makefile
# Detect system OS.
ifeq ($(OS),Windows_NT)
    detected_OS := Windows
else
    detected_OS := $(shell sh -c 'uname -s 2>/dev/null || echo not')
endif
```

### 动态决定C编译器

根据之前检测的detected_OS来动态指定CC（或CXX）编译器。

```Makefile
# Clean the default value of CC or CXX.
CC=

# Detect proper C compiler by system OS.
ifndef CC
	ifeq ($(detected_OS),Windows)
		CC=cl
	else ifeq ($(detected_OS),Darwin)
		CC=clang
	else
		CC=gcc
	endif
endif
```

同时也可以通过后期编译命令指定专用的编译器：

```shell
$ make CC=gcc-4.9
```

### 动态设置C编译器的参数(CFLAGS)

由于Visual C++的CFLAGS参数和GCC（或Clang）不兼容，所以需要使用条件判断进行区分。另外通过DEBUG来区分Debug和Release两种版本。

```Makefile
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
```


### 清理命令适配
只有Windows上编译的RM不兼容，进行特殊适配即可，其他平台则默认是rm -f命令。

```Makefile
# Set proper RM on Windows.
ifeq ($(detected_OS),Windows)
	RM=del /q /f
endif

export RM
```

### 编译目录文件
根据不同的C编译器设置不同的生成目标名称。

```Makefile
# Modify it if more than one source files.
SOURCE=$(PROGRAM:.exe=).c

# Set object files.
ifeq ($(CC),cl)
	OBJS=$(SOURCE:.c=.obj)
else
	OBJS=$(SOURCE:.c=.o)
endif  # OBJS

export OBJS
```

### 编译目标文件命令
根据不同C编译器编译目标文件。

```Makefile
%.obj: %.c
	$(CC) /c $< $(CFLAGS)

%.o: %.c
	$(CC) -c $< $(CFLAGS)
```

### 编译可执行文件命令
根据不同C编译器使用不同的参数来编译执行。

```Makefile
$(PROGRAM): $(OBJS)
ifeq ($(CC),cl)
	$(CC) /Fe:$(PROGRAM) $(OBJS) $(CFLAGS) $(LDFLAGS) $(LDLIBS)
else
	$(CC) -o $(PROGRAM) $(OBJS) $(CFLAGS) $(LDFLAGS) $(LDLIBS)
endif
```



