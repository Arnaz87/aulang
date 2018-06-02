import cobre.system { void println (string); }
import cobre.string { string itos(int); int length (string); }

bool f (bool b) {
  if (b) println("true");
  else println("false");
  return b;
}

void main () {
  f(!f(true) && f(true));
}