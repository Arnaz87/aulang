
modules=dist/culang dist/culang.lexer dist/culang.parser dist/culang.compiler

.PHONY: dist install uninstall

dist/culang: culang.cu
	cobre culang culang.cu dist/culang

dist/culang.%: %.cu
	cobre culang $*.cu $@

dist: $(modules)

install: dist
	cd dist ;\
	cobre --install culang ;\
	cobre --install culang.lexer ;\
	cobre --install culang.parser ;\
	cobre --install culang.compiler ;\

uninstall:
	cobre --remove culang
	cobre --remove culang.lexer
	cobre --remove culang.parser
	cobre --remove culang.compiler
