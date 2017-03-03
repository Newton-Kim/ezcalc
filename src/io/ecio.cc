/* Copyright (C) 2015 Newton Kim
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditiong:
*
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/
#include "ecio.h"
#include "ezvm/ezval.h"
#include <iostream>
#include <sstream>
#include <stdexcept>

class ecIoPrint : public ezNativeCarousel {
private:
  ostream &m_io;

public:
  ecIoPrint(ostream &io);
  void run(ezGC &gc, vector<ezValue *> &args, vector<ezValue *> &rets);
};

ecIoPrint::ecIoPrint(ostream &io) : ezNativeCarousel(), m_io(io) {}

void ecIoPrint::run(ezGC &gc, vector<ezValue *> &args,
                    vector<ezValue *> &rets) {
  rets.clear();
  stringstream ss;
  size_t len = args.size();
  for (size_t i = 0; i < len; i++) {
    ezValue *v = args[i];
    switch (v->type) {
    case EZ_VALUE_TYPE_INTEGER:
      ss << ((ezInteger *)v)->to_integer();
      break;
    case EZ_VALUE_TYPE_FLOAT:
      ss << ((ezFloat *)v)->to_float();
      break;
    case EZ_VALUE_TYPE_COMPLEX: {
      complex<double> c = ((ezComplex *)v)->to_complex();
      ss << c.real();
      if (c.imag() > 0)
        ss << "+";
      ss << c.imag() << "j";
    } break;
    case EZ_VALUE_TYPE_STRING:
      ss << ((ezString *)v)->to_string();
      break;
    case EZ_VALUE_TYPE_BOOL:
      ss << (((ezBool *)v)->to_bool() ? "true" : "false");
      break;
    case EZ_VALUE_TYPE_NULL:
      //      ss << "nil";
      break;
    default:
      ss << hex << (void *)v << dec;
    }
  }
  ss << endl;
  m_io << ss.str();
}

void ecIO::load(char ***symtab, ezValue ***constants) {
  static ecIoPrint io_stdout(cout), io_stderr(cerr);
  static const char *io_symtab[] = {"stdout", "stderr", NULL};
  static ezValue *io_constants[] = {&io_stdout, &io_stderr, NULL};
  *symtab = (char **)io_symtab;
  *constants = io_constants;
}
