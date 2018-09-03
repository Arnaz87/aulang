
import auro.buffer {
  type buffer;
  int size (buffer) as bufsize;
  buffer `new` (int size) as newbuf;
  void set (buffer, int pos, int val) as bufset;
}
import auro.string {
  string `new` (buffer) as newstr;
  buffer tobuffer (string);
}
import auro.io {
  type file; 
  type mode;
  mode r ();
  mode w ();
  file open (string, mode);
  buffer read (file, int);
  void write (file, buffer);
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

file _open (string path, string dummy) { return open(path, w()); }
void _write (file f, string str) { write(f, tobuffer(str)); }
void writebyte (file f, int b) {
  buffer buf = newbuf(1);
  bufset(buf, 0, b);
  write(f, buf);
}