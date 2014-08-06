.PHONY: all test clean

all: out

c.l.cpp: c.l
	flex -o $@ $^

c.y.hpp c.y.cpp: c.y
	bison -d -o c.y.cpp $^

out: c.y.cpp c.l.cpp
	g++ -ll -ly $^ -o $@

test:
	./out $@

vim: c.l c.y
	vim -p $^

macvim: c.l c.y
	open -a macvim $^

edit: vim out
e: edit

em: macvim

clean:
	rm -rf c.l.cpp c.y.cpp c.y.hpp out
