.PHONY: all test clean

all: out

c.l.cpp: c.l
	flex -o c.l.cpp c.l

c.y.hpp c.y.cpp: c.y
	bison -d -o c.y.cpp c.y

out: c.y.cpp c.y.hpp c.l.cpp
	g++ -ll -ly -o out c.y.cpp c.l.cpp

test:
	./out test

vim:
	vim -p c.l c.y

edit: vim out
e: edit

clean:
	rm -rf c.l.cpp c.y.cpp c.y.hpp out
