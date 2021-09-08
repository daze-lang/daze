main:
	v . && mv ./daze ./bin/daze && sudo cp ./bin/daze /usr/bin/daze

run:
	./bin/daze
run-vm:
	./bin/vm

build-and-run:
	make clean && make && ./bin/daze build demo/lang.daze && ./lang

changelog:
	git cliff > CHANGELOG.md

clean:
	find . -maxdepth 1 -type f -executable -exec rm {} +