.PHONY: all test test1 test2 clean

all: out

c.l.cpp: c.l c.y.hpp
	flex -o $@ $^

c.y.hpp c.y.cpp: c.y
	bison -d -o c.y.cpp $^

out: c.y.cpp c.l.cpp
	g++ -ll -ly $^ -o $@

test1:
	./out $@

test2:
	./out $@

test: test1 test2

vim: c.l c.y
	vim -p $^

macvim: c.l c.y
	open -a macvim $^

edit: vim out
e: edit

em: macvim

clean:
	rm -rf c.l.cpp c.y.cpp c.y.hpp out
