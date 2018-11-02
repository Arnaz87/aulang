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

# Basics

~~~c
// This functionality, although mildly inonvinient, is enough to describe
// every top level item.

// Global modules
module system = import auro.system;
// Member modules of other modules
module unsafe = system.unsafe;
// Module definitions
module int_param {
  T = int;
  // Alternative syntax
  int as T;
}
module int_param { T = int; }
// Parametric modules
module int_arr_mod = array(intparam);

// Types can only be members of other modules
type int_arr = int_arr_mod.array;

// functions can be either from another module
void println (string param) = system.println;
// Or defined here
void main () {}

// Any non ternary nor logic expression is valid
int my_const = 40 + 2;

export mymodule;

// Item name syntax is allowed when importing items from modules and when
// defining items. $ is replaced with the metaname separator 0x1d.
int arr$get
~~~

# Imports

~~~c
// The compiler knows the contents of any visible source file or auro module
import auro.system.int;
import auro.system.*;

// imported items can be used directly by their name or be preceded by
// it's module name
int a;
auro.system.int c;
~~~

# Generics

~~~c
// A generic module is an unbuilt functor, all items of the module are generic
// and require generic parameters, with which a module is built.
// If a module has been used before with the same generic parameters, that
// previous built module is used instead.

module map_mod $<> = import auro.utils.map;
type map = map_mod.map;
map$<T=string, K=int> myarr = new map$<T=string, K=int>();

// Equivalent to
module int_map_params { K = string, V = int; }
module int_map_mod = map_mod(int_map_params);
type int_map = int_map_mod.map;
int_map myarr = new int_map();

// Imported modules are generic when they use items of their argument modules.
import auro.utils.arraylist;

// When the arguments are not named, they are implied to be named like the
// integers in base 10 starting from 0 that match their position
arraylist$<any> arr = new arraylist$<`0` = any>();
~~~


# Imports

~~~c
// Imports the module "a.b", where '.' is replaced with the field separator
import a.b {
  // Imports the function "f" from the module, and makes
  // it accessible in the rest of the code as "f"
  void f (int);

  // The same as above, the argument names are ignored
  void f (int arg0);

  // Same but in this file, the function is named ff
  void f (int) as ff;

  // arguments and return types work as with regular functions
  int, char f2 (int, int);

  // Unlike non imported functions, the names can also have field
  // separators like modules, and metanames can also be used, each
  // separated with '$', but to be used in normal code they have to
  // be aliased because there is no syntax for separators
  void f3.a$b () as f3;

  // This can be used with f4 as no other function has the same main name
  void f4$a ();

  // Imports the type t and is used with "t"
  type t;

  // Identifiers and aliases work like with imported functions
  type t2.a:b as t2;

  // Types can have bodies, alias is optional, cannot end in ';'
  type t as tt {
    // Functions imported inside type bodies are accessed as methods,
    // they are equivalent to a function imported normally but
    // with the type name added as a metaname:
    // void f1:t ();
    void f1 ();

    // Methods with the "get" and "set" metanames are accessed as fields,
    // they need not be aliased, if aliased they are used as methods.
    int x1$get ();
    void x1$set (int);

    // All methods, including fields are inferred to have a first argument
    // of type t, and is automatically named "this".
  }
}
~~~

# Structs

This will be renamed to records

~~~c
// Equivalent to:
// import cobre.record (A as `0`, B as `1`) { type `` as T; }
struct T {
  // A field. Imports from that same module the functions
  // get0 and set0, as if they were named a:get and a:set,
  // and if non private, they are exported as a:T:get and a:T:set
  A a;

  // The same as above, but because it is the second argument, the type B
  // is passed second in the module arguments, and the getters and
  // setters are get1 and set1 (index of the fields is 0 based)
  B b;

  // A method, receives an implicit first argument of type T named this,
  // and if exported, is exported with an aditional metaname "T"
  void f () {}

  // Setters and getters methods can act like fileds of that name
  int c$get () {return 1;}
  void c$set (int c) {}

  // All of these functions work with any struct declared in any other
  // module with the same types in the same order
}
~~~

# Types

~~~c
// The same as a struct, but creates a separate type not compatible with
// other equivalent structs or types. It's equivalent to:
// import cobre.record (A, B) { type `` as _T; }
// import cobre.typeshell (_T) { type `` as T; }
type T {
  // Fields and methods work the same as with structs
}

// A type with a base, creates a type MyInt that is not compatible with int
type MyInt (int) {
  // Fields do not work, only methods, including getters and setters
  int f$get () {
    // The as operator can convert a value of MyInt to an int.
    int x = this as int;
    return x;
  }
}

// Types without body are external, that is they are exported by the module
// butd defined elsewhere.
type T;
~~~

# Function statement

~~~c
// Work just as C functions
void f (int x) { int y = x; }

// Cu functions ca return multiple values
int, int incdec (int x) { return x+1, x-1; }

// Parameters don't need names, but then they are useless
void f (int) { }

// Unlike C, parameters can't share types, the second parameter is not
// an int named float, is a float without name
void f (int a, float) { }

// Functions without body mean it's present in the module but not defined,
// for example if it's platform provided or the implementation is secret.
void f (); // end with semicolon
~~~

# Modules

~~~c
// Types, functions and constants are all items, they are distributes
// in modules, which are items themselves.
module M {
  // each item in the module has to refer to an existing item and
  // define a name in the module.
  print as p;
  // now print can be used with M.p
}


// Just as with types and function, modules without body guarantee existence
// but do not provide implementations
module MA;

// By default all items are exported, but they can be marked private
private void f () {}
private module MB {}

// Private and imported items, can be reexported
export f as g;
export int as T;
export MB as MB; // Equivalent to not marking it private at all

// Not allowed, because another item is already exported with that name
export M as MA;

// Overrides all exported items, and exports only the items defined in M
export module M;

// Shortcut to not define a separate module
export module { print as p; }


/*/ Ambiguity
// Function in cobre.system, Java style
import cobre.system.print;
// Module cobre.system itself
import cobre.system;
// Module in scope
import M; */


// This removes the ambiguity, but is ugly
// Imports the print function from global "cobre.system"
import cobre.system.print;
// Imports the global module "cobre.system" itself into scope
import module cobre.system;
// Imports many items from global "cobre.system"
import cobre.system {}
// Imports many items from module in scope "M"
import module M {}


// Another alternative
import cobre.system; // Error: module cobre not found
import cobre.system.print;
module array = import cobre.array;
module M = array(int as `0`);
import module M { type intArr; }
import module array (string as `0`) {
  type strArr;
}
import module M; // Error: expected '{'


// Use items of a module in scope
import module M {
  // The same as importing a global module
  void p (string) as print2;
}
~~~

# Arguments

~~~c
private module M {
  int as T;
  main as f;
}
// A module can be passed to an imported module for it to use it's items
import some.module (module M) {}

// shortcut syntax to avoid creating too many modules
import some.module (int as T, main as f) {}

// the passed module is defined as a special module
import module argument {
  type T;
  void f ();
}
~~~

# Control flow

Control flow is also like C's, but there are no switch, for loops nor do while loops. There are labels and goto statements, and loops can be labeled so that break and continue statements can refer to outer loops. It is legal to jump out of loops and into them.

# Multiple assignment

Multiple assignment in declaration statements works like in C, but multiple variables can be assigned at once in a single statement when the assigned expression is a call to a function with multiple results. In this situation, the left side of the statement can have multiple variables separated by commas, and each one must match the function return types. But it must not be a declaration, as that would only assign the last variable and the rest would be uninitialized, like in C.

# Statics

Statics are like module level variables, they have the same syntax and behave the same as regular variables in function bodies, with the exception that they must be initialized immediately when declared.

Use them sparingly, as statics very likely to change in Cobre.

# Expressions

Expressions can be unary operations, binary operations and function calls.

Arithmetic operations are overloaded for int and float, the addition operation is also overloadod for string. Logical operations are short circuited.

Cu doesn't cast expressions implicitly, nor does an explicit cast expression exists, if casting is desired it must be trough library functions.

Function calls that return multiple values, when used in expressions an not in multi assignments, only use the first result and discard the rest.

## Function expressions

~~~c
// if the function is declared, it can be refered to by its name
foreach(xs, some_function);

// @ indicates an anonymous function, it's followed by a
// nameless function definition (maybe void is optional?)
foreach(xs, @void (int x) {println(itos(x));})

// if preceded by a value, a closure is created over that value,
// inside the function it's refered as "this"
int n = 42;
int[] ys = map(xs, n @ int (int x) {return x + this;})
~~~
