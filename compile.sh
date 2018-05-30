#!/bin/env sh
FILES=$'culang culang\x1flexer culang\x1fparser culang\x1fcompiler culang\x1futil'
if [ "$1" == "clean" ]; then
  rm -f $FILES
  exit
fi
if [ "$1" == "test" ]; then
  sh compile.sh
fi
compile () { echo compiling $1; cobre6 culang $1.cu culang$'\x1f'$1; }
compile util &&
compile lexer &&
compile parser &&
compile compiler &&
echo compiling culang &&
cobre6 culang culang.cu culang
if [ "$1" == "dist" ]; then
  cp $FILES dist/
fi
