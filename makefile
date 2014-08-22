.PHONY: all test clean

all: out

c.l.cpp: c.l c.y.hpp
	flex -o $@ $^

c.y.hpp c.y.cpp: c.y
	bison -d -o c.y.cpp $^

out: c.y.cpp c.l.cpp ast.hpp
	g++ -ll -ly c.y.cpp c.l.cpp -o $@

UnitTestCase.class:
	javac UnitTestCase.java

case: out UnitTestCase.class
	java UnitTestCase test1 test2 test3 test4 test5

et:
	vim UnitTestCase.java

test%: out
	./out unittests/$@.testcase

test: case

vim: c.l c.y
	vim -p $^

macvim: ast.hpp c.l c.y
	open -a macvim $^

edit: vim out
e: edit

em: macvim

clean:
	rm -rf c.l.cpp c.y.cpp c.y.hpp out UnitTestCase.class
