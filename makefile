
.PHONY: dist install uninstall

dist:
	#sh compile.sh dist

install: dist
	cd dist ;\
	cobre --install culang ;\
	cobre --install $'culang\x1futil' ;\
	cobre --install $'culang\x1flexer' ;\
	cobre --install $'culang\x1fparser' ;\
	cobre --install $'culang\x1fcompiler' ;\

uninstall:
	cobre --remove culang
	cobre --remove culang.util
	cobre --remove culang.lexer
	cobre --remove culang.parser
	cobre --remove culang.compiler
