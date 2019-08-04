# Auro language (Aulang)

*[2018-01-09 16:45]*

The Auro language is a thin layer on top of the Auro module format similar to C.

# Lexical

Lexically Aulang is the same as C with the following remarks:

- There is no pointer related syntax, but there is array syntax
- String literals have type `string` instead of `char[]`
- A quoted identifier is like a string but delimited with \` instead of " and has the same meaning as a regular identifier
- The set of reserved keywords is different than C's:
  + true, false, void, null, new, if, else, while, return, continue, break, goto, type, module, import, export, as
- Default types are not keywords but implicitly imported types:
  + bool, int, float, string
- There is no octal integer literal

Note: the code snippets are marked as C to take advantage of markdown syntax highlighters, but it's actually Auro code.

# Top Level Statements

~~~c
// Global modules
module system = import auro.system;
// Member modules of other modules
module unsafe = system.unsafe;
// Module definitions
module int_param {
  T = int;
}
// Parametric modules
module int_arr_mod = array(intparam);

// Types can only be members of other modules
type int_arr = int_arr_mod.array;

// functions can be either from another module
void println (string msg) = system.println;
// Or defined here
void main () {}

// Any non ternary nor logic expression is valid
int my_const = 40 + 2;

export mymodule;

// Item name syntax is allowed when importing items from modules and when
// defining items. $ is replaced with the metaname separator 0x1d.
int arr$get
~~~

# Control flow

Control flow is also like C's, but there are no switch, for loops nor do while loops. There are labels and goto statements, and loops can be labeled so that break and continue statements can refer to outer loops. It is legal to jump out of loops and into them.

# Multiple assignment

Multiple assignment in declaration statements works like in C, but multiple variables can be assigned at once in a single statement when the assigned expression is a call to a function with multiple results. In this situation, the left side of the statement can have multiple variables separated by commas, and each one must match the function return types. But it must not be a declaration, as that would only assign the last variable and the rest would be uninitialized, like in C.

# Statics

Statics are like module level variables, they have the same syntax and behave the same as regular variables in function bodies, with the exception that they must be initialized immediately when declared.

*Not yet implemented.*

# Expressions

Expressions can be unary operations, binary operations and function calls.

Arithmetic and relation operations are overloaded for ints and floats. The addition and equality operations are overloadod for strings. Logical operations are short circuited and only work with booleans. there's no operator precedence yet but it's planned.

Values aren't casted implicitly, nor is there an explicit cast expression, if casting is desired it must be trough library functions.

Function calls that return multiple values, when used in expressions an not in multi assignments, only use the first result and discard the rest.

# Metadata

~~~c
#metadata ("one", 2, (main, string));
~~~

Each metadata statement declares an individual metadata node, which will be added to all the others. A node can be a string, an integer, a parenthezised list of nodes, or a function or type, which when compiled point to their ids.
