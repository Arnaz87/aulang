
import auro.system {
  void println (string);
  int argc ();
  string argv (int);
  void exit(int);
}

import auro.buffer { type buffer; }
import auro.string { string `new` (buffer) as newstr; }

import auro.io {
  type file;
  type mode;
  mode r ();
  mode w ();
  file open (string, mode);
  buffer read (file, int);
  void write (file, buffer);
  void close (file);
  bool eof (file);
}

import culang.compiler { buffer compile (string src); }

string readall (file f) {
  string str = "";

  repeat:
  buffer buf = read(f, 512);
  str = str + newstr(buf);
  if (eof(f)) {} else goto repeat;

  return str;
}

void main () {
  if (argc() == 3) {} else {
    println("Usage: " + argv(0) + " <input> <output>");
    exit(1);
  }

  file in_file = open(argv(1), r());
  string src = readall(in_file);
  close(in_file);

  buffer buf = compile(src);
  file out_file = open(argv(2), w());
  write(out_file, buf);
  close(out_file);
}