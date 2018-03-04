# Culang

C-like programming language running on the [Cobre VM](https://github.com/Arnaz87/cobrevm). The language is complete enough to be written in itself, but it's not very practical yet.

**TODO**:

- scopes (currently a single scope per function)
- Typechecking
- float type
- char type
- Multiple sized primitives
- Array syntax
- Module syntax
- Statics/Constants
- boolean expressions and ternary
- for, switch, do while, break, continue
- struct-like types
- unions
- null

To install it, you first need to install the [Cobre VM](https://github.com/Arnaz87/cobrevm), and then run `make install`. Then to compile a cobre file, run `cobre culang <source.cu> <target>` and run it with `cobre <target>`. Aditionally, that module can then be installed system-wide with `cobre --install <target>`
