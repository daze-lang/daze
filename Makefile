main:
	cd compiler && v . && mv ./compiler ../bin/daze && sudo cp ../bin/daze /usr/bin/daze

vm:
	cd compiler/vm && v . && mv ./vm ../../bin/vm

run:
	./bin/daze
run-vm:
	./bin/vm

build-and-run:
	make clean && make && ./bin/daze build demo/lang.daze && ./lang

clean:
	find . -maxdepth 1 -type f -executable -exec rm {} +