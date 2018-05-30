
.PHONY: dist install uninstall

dist:
	sh compile.sh dist

install: dist
	cd dist ;\
	cobre --install culang ;\
	cobre --install culang.util ;\
	cobre --install culang.lexer ;\
	cobre --install culang.parser ;\
	cobre --install culang.compiler ;\

uninstall:
	cobre --remove culang
	#cobre --remove culang.util
	cobre --remove culang.lexer
	cobre --remove culang.parser
	cobre --remove culang.compiler
