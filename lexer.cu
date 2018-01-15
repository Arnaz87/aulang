
import cobre.system {
  void print (string);
  string readall (string);
}

import cobre.record(string, string) {
  type `` as token;
  token new(string, string) as newToken;
  string get0(token) as getType;
  string get1(token) as getVal;
}

import cobre.string {
  int codeof (char);
  char, int charat(string, int);
  int length (string) as strlen;
  string add (string, char) as addch;
  string itos(int);
}

void printToken (token tk) {
  print(getType(tk) + " " + getVal(tk));
}

bool isDigit (char ch) {
  int code = codeof(ch);
  if (code >= 48) { // 0
    if (code <= 57) { // 9
      return 0<1; // true
    }
  }
  return 0<0; // false
}

bool isAlpha (char ch) {
  int code = codeof(ch);

  if (code == 95) // _
    return 0<1;

  if (code >= 65) // A
    if (code <= 90) // Z
      return 0<1;

  if (code >= 97) // a
    if (code <= 122) // z
      return 0<1;

  return 0<0; // false
}

bool isAlphaNum (char ch) {
  if (isAlpha(ch)) return 0<1;
  if (isDigit(ch)) return 0<1;
  return 0<0; // false
}

bool isKw (string s) {
  if (s == "true") return 0<1;
  if (s == "false") return 0<1;
  if (s == "void") return 0<1;

  if (s == "if") return 0<1;
  if (s == "else") return 0<1;
  if (s == "while") return 0<1;

  if (s == "return") return 0<1;
  if (s == "continue") return 0<1;
  if (s == "break") return 0<1;
  if (s == "goto") return 0<1;

  if (s == "import") return 0<1;
  if (s == "as") return 0<1;
  if (s == "type") return 0<1;
  
  return 0<0;
}

bool isOp (char ch) {
  int code = codeof(ch);
  if (code == 40) return 0<1; // (
  if (code == 41) return 0<1; // )
  if (code == 42) return 0<1; // *
  if (code == 43) return 0<1; // +
  if (code == 44) return 0<1; // ,
  if (code == 45) return 0<1; // -
  if (code == 46) return 0<1; // .
  if (code == 58) return 0<1; // :
  if (code == 59) return 0<1; // ;
  if (code == 123) return 0<1; // {
  if (code == 125) return 0<1; // }
  return 0<0; // false
}

bool maybeEq (char ch) {
  int code = codeof(ch);
  if (code == 33) return 0<1; // !
  if (code == 60) return 0<1; // <
  if (code == 61) return 0<1; // =
  if (code == 62) return 0<1; // >
  return 0<0; // false
}

bool isSpace (char ch) {
  int code = codeof(ch);
  if (code == 9)  { return 0<1; } // \t
  if (code == 10) { return 0<1; } // \n
  if (code == 32) { return 0<1; } // ' '
  return 0<0; // false
}

bool isQuote (char ch) {
  int code = codeof(ch);
  if (code == 34) { return 0<1; } // "
  if (code == 39) { return 0<1; } // '
  if (code == 96) { return 0<1; } // `
  return 0<0; // false
}

void tokens (string input) {
  int len = strlen(input);
  int pos = 0;
  char ch;

  ch, pos = charat(input, pos);
  while (pos < len) {
  skipspace:
    while (isSpace(ch)) {
      if (pos >= len) { goto end; }
      ch, pos = charat(input, pos);
    }

    int code = codeof(ch);
    token tk;

    if (codeof(ch) == 47) { // '/'
      if (pos < len)
        ch, pos = charat(input, pos);
      if (codeof(ch) == 47) { // Start line comment
        linecom:
          if (codeof(ch) == 10) // \n
            goto endlinecom;
          if (pos >= len) goto end;
          ch, pos = charat(input, pos);
          goto linecom;
        endlinecom:
        if (pos < len) ch, pos = charat(input, pos); // skip newline
        goto skipspace;

      } else {
        tk = newToken("/", "");
      }
    }

    else if (isDigit(ch)) {
      string val = "";
      while (isDigit(ch)) {
        val = addch(val, ch);
        if (pos >= len) { goto enddigit; }
        ch, pos = charat(input, pos);
      }
      enddigit:
      tk = newToken("num", val);
    }

    else if (isAlpha(ch)) {
      string val = addch("", ch);
      if (pos >= len) { goto endname; }
      ch, pos = charat(input, pos);
      while (isAlphaNum(ch)) {
        val = addch(val, ch);
        if (pos >= len) { goto endname; }
        ch, pos = charat(input, pos);
      }
      endname:
      if (isKw(val)) tk = newToken(val, "");
      else tk = newToken("name", val);
    }

    else if (isOp(ch)) {
      tk = newToken(addch("", ch), "");
      if (pos < len)
        ch, pos = charat(input, pos);
    }

    else if (maybeEq(ch)) {
      string op = addch("", ch);
      if (pos < len) {
        ch, pos = charat(input, pos);
        if (codeof(ch) == 61) {
          op = op + "=";
          if (pos < len)
            ch, pos = charat(input, pos);
        }
      }
      tk = newToken(op, "");
    }

    else if (isQuote(ch)) {
      int quoteCode = codeof(ch);
      string val = "";
      beginq:
        if (pos >= len) {
          print("Unfinished string");
          goto end;
        }
        ch, pos = charat(input, pos);

        // Closing quote
        if (codeof(ch) == quoteCode) goto endq;

        if (codeof(ch) == 92) { // Escape
          if (pos >= len) {
            print("Unfinished string");
            goto end;
          }
          ch, pos = charat(input, pos);
          val = addch(val+"\\", ch);
          goto beginq;
        }

        val = addch(val, ch); // Anything else
        goto beginq;
      endq:
      if (pos < len) ch, pos = charat(input, pos); // Skip closing quote
      if (quoteCode == 34) tk = newToken("str", val);   // "
      if (quoteCode == 39) tk = newToken("char", val);  // '
      if (quoteCode == 96) tk = newToken("name", val);  // `
    }

    else {
      print(addch("Unexpected character ", ch));
      goto end;
    }

    printToken(tk);
  }
  end:
  return;
}

void main () {
  string src = readall("../culang/lexer.cu");
  tokens(src);
  //tokens(" 756 3 void _a if ifn {.}() =<=<+ `x` \"\\\"\"");
}