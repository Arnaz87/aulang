#!/bin/env bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "help" ]; then
  echo "bash build.sh [ -h | --help | help | test | dist | install | uninstall ]"
  exit
fi

FILES="culang culang.lexer culang.parser culang.compiler culang.util"

# Este comando remplaza todas las palabras por culang.palabra
# echo $X | sed -E 's/\w+/culang.&/g'

if [ "$1" == "temp" ]; then
  cd dist; cp $FILES ..; cd ..
fi

if [ "$1" == "bootstrap" ]; then
  bash build.sh temp &&
  bash build.sh
  rm -f $FILES
  exit
fi

if [ "$1" == "test" ]; then
  bash build.sh temp &&
  echo compiling out &&
  auro culang test.cu out &&
  echo running out &&
  auro out
  rm -f $FILES
  exit
fi

if [ "$1" == "uninstall" ]; then
  for a in $FILES; do
    auro --remove $a
  done
  exit
fi

if [ "$1" != "install" ]; then
  compile () { echo compiling $1; auro culang $1.cu dist/culang.$1; }
  compile util &&
  compile lexer &&
  compile parser &&
  compile compiler &&
  echo compiling culang &&
  auro culang culang.cu dist/culang ||
  (echo "Could not compile files"; exit)
fi

if [ "$1" == "install" -o "$1" == "install-build" ]; then
  cd dist
  for a in $FILES; do
    auro --install $a
  done
  exit
fi
