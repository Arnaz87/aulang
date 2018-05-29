
import cobre.buffer { type buffer; int size (buffer) as bufsize; }
import cobre.string { string `new` (buffer) as newstr; }
import cobre.io {
  type file; 
  type mode;
  mode r ();
  file open (string, mode);
  buffer read (file, int);
  bool eof (file);
}

string readall (string path) {
  file f = open(path, r());
  string str = "";

  repeat:
  buffer buf = read(f, 128);
  str = str + newstr(buf);
  if (eof(f)) {} else goto repeat;

  return str;
}