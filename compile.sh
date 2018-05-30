#!/bin/env sh
if [ "$1" == "clean" ]; then
  rm -f culang culang.lexer culang.parser culang.compiler
  exit
fi
if [ "$1" == "test" ]; then
  sh compile.sh
fi
compile () { echo compiling $1; cobre culang $1.cu culang.$1; }
compile lexer &&
compile parser &&
compile compiler &&
echo compiling culang &&
cobre culang culang.cu culang