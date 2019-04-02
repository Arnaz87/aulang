#!/bin/env bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "help" ]; then
  echo "bash build.sh [ -h | --help | help | test | dist | install | uninstall ]"
  exit
fi

FILES="aulang aulang.util aulang.node aulang.item aulang.lexer aulang.parser aulang.writer aulang.codegen aulang.compiler"

# Este comando remplaza todas las palabras por aulang.palabra
# echo $X | sed -E 's/\w+/aulang.&/g'

if [ "$1" == "temp" ]; then
  cd dist; cp $FILES ..; cd ..
fi

if [ "$1" == "bootstrap" ]; then
  bash build.sh &&
  (cd dist; cp $FILES ..) &&
  echo Bootstrapping &&
  bash build.sh
  rm -f $FILES
  exit
fi

if [ "$1" == "test" ]; then
  bash build.sh &&
  echo compiling out &&
  auro --dir dist/ aulang test.au out &&
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
  rm dist/*

  compile () { echo compiling $1; auro culang src/$1.cu dist/aulang.$1; }
  aucompile () { echo compiling $1; auro aulang src/$1.au dist/aulang.$1; }

  compile util &&
  compile node &&
  compile item &&
  aucompile lexer &&
  aucompile parser &&
  compile writer &&
  compile codegen &&
  compile compiler &&
  echo compiling aulang &&
  auro culang src/aulang.cu dist/aulang

  if [ $? == 1 ]; then
    echo "Could not compile files"
    exit 1
  fi
fi

if [ "$1" == "install" -o "$1" == "install-build" ]; then
  cd dist
  for a in $FILES; do
    auro --install $a
  done
  exit
fi
