
import cobre.function () {
  type `` as Fn;
  module `new`;
  void apply (Fn);
}

import module `new` (f as `0`) {
  Fn `` () as fcns;
}

export `new` as fnew;

import cobre.system { void print (string); }
private void f () { print("Hola Mundo!"); }

/*module fnFunctor = import cobre.function;
module emptyArg {}
module fnM = fnFunctor(module emptyArg);

import module fnM {
  type `` as Fn;
  module `new` as newFunctor;
  void call (Fn);
}

module newArg { f as `0`; }
module newM = newFunctor(module newArg);
import module newM {
  Fn `` () as fcns;
}*/

void main () {
  Fn g = fcns();
  apply(g);
}

//void main () { f(); }
