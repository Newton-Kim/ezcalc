#include "ecmath.h"
#include <functional>

inline void mathf_1arg(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets, function<ezValue *(ezValue*)> funcf, function<ezValue *(ezValue*)> funcc) {
  rets.clear();
  if(args.empty()) runtime_error("sin function has no argument.");
  switch(args[0]->type) {
    case EZ_VALUE_TYPE_INTEGER:
    case EZ_VALUE_TYPE_FLOAT:
      rets.push_back((ezValue*)gc.add((ezGCObject*) funcf(args[0])));
      break;
    case EZ_VALUE_TYPE_COMPLEX:
      rets.push_back((ezValue*)gc.add((ezGCObject*) funcc(args[0])));
      break;
    default:
      rets.push_back(ezNull::instance());
      rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid argument type")));
      break;
  }
}

class ecSin: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(sin(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(sin(arg->to_complex()));});
  }
};

class ecCos: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(cos(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(cos(arg->to_complex()));});
  }
};

class ecTan: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(tan(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(tan(arg->to_complex()));});
  }
};

class ecSinh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(sinh(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(sinh(arg->to_complex()));});
  }
};

class ecCosh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(cosh(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(cosh(arg->to_complex()));});
  }
};

class ecTanh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(tanh(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(tanh(arg->to_complex()));});
  }
};

class ecAsin: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(asin(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(asin(arg->to_complex()));});
  }
};

class ecAcos: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(acos(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(acos(arg->to_complex()));});
  }
};

class ecAtan: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(atan(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(atan(arg->to_complex()));});
  }
};

class ecLog10: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(log10(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(log10(arg->to_complex()));});
  }
};

class ecLog: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(log(arg->to_float()));}, [](ezValue* arg) {return new ezComplex(log(arg->to_complex()));});
  }
};

class ecSqrt: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {
      double v = arg->to_float();
      return (v >= 0) ? (ezValue*)new ezFloat(sqrt(v)) : (ezValue*)new ezComplex(complex<double>(0, sqrt(-v)));
    }, [](ezValue* arg) {return new ezComplex(sqrt(arg->to_complex()));});
  }
};

class ecAbs: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    rets.clear();
    if(args.empty()) runtime_error("sin function has no argument.");
    switch(args[0]->type) {
      case EZ_VALUE_TYPE_INTEGER:
        {
          int v = args[0]->to_integer();
          rets.push_back((ezValue*)gc.add((ezGCObject*) new ezInteger(v > 0 ? v : -v)));
        }
        break;
      case EZ_VALUE_TYPE_FLOAT:
        {
          double v = args[0]->to_float();
          rets.push_back((ezValue*)gc.add((ezGCObject*) new ezFloat(v > 0 ? v : -v)));
        }
        break;
      case EZ_VALUE_TYPE_COMPLEX:
        {
          complex<double> v = args[0]->to_complex();
          rets.push_back((ezValue*)gc.add((ezGCObject*) new ezFloat(abs(v))));
        }
        break;
      default:
        rets.push_back(ezNull::instance());
        rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid argument type")));
        break;
    }
  }
};

class ecPow: public ezNativeCarousel {
private:
  ezValue* m_e;
public:
  ecPow(ezValue* e): m_e(e) {}

  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    rets.clear();
    if(args.empty()) runtime_error("sin function has no argument.");
    switch(args[0]->type) {
      case EZ_VALUE_TYPE_INTEGER:
        {
          int v = args[0]->to_integer();
          if(args[1]->type == EZ_VALUE_TYPE_INTEGER || args[1]->type == EZ_VALUE_TYPE_FLOAT) {
            double e = args[1]->to_float();
            rets.push_back((ezValue*)gc.add((ezGCObject*) new ezInteger(pow(v, e))));
          } else {
            rets.push_back(ezNull::instance());
            rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid exponent type")));
          }
        }
        break;
      case EZ_VALUE_TYPE_FLOAT:
        {
          double v = args[0]->to_float();
          if(args[0] == m_e || v == m_e->to_float()) {
            switch(args[1]->type) {
              case EZ_VALUE_TYPE_INTEGER:
              case EZ_VALUE_TYPE_FLOAT:
                rets.push_back((ezValue*)gc.add((ezGCObject*) new ezComplex(exp(args[1]->to_float()))));
                break;
              case EZ_VALUE_TYPE_COMPLEX:
                rets.push_back((ezValue*)gc.add((ezGCObject*) new ezComplex(exp(args[1]->to_complex()))));
                break;
              default:
                rets.push_back(ezNull::instance());
                rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid exponent type")));
                break;
            }
          } else if(args[1]->type == EZ_VALUE_TYPE_INTEGER || args[1]->type == EZ_VALUE_TYPE_FLOAT) {
            double e = args[1]->to_float();
            rets.push_back((ezValue*)gc.add((ezGCObject*) new ezFloat(pow(v, e))));
          } else {
            rets.push_back(ezNull::instance());
            rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid exponent type")));
          }
        }
        break;
      default:
        rets.push_back(ezNull::instance());
        rets.push_back((ezValue*)gc.add((ezGCObject*) new ezString("invalid argument type")));
        break;
    }
  }
};

void ecMath::load(char ***symtab, ezValue ***constants) {
  static ezFloat ezPi(M_PI), ezExp(exp(1));
  static ecSin math_sin;
  static ecCos math_cos;
  static ecTan math_tan;
  static ecSinh math_sinh;
  static ecCosh math_cosh;
  static ecTanh math_tanh;
  static ecAsin math_asin;
  static ecAcos math_acos;
  static ecAtan math_atan;
  static ecLog math_log;
  static ecLog10 math_log10;
  static ecSqrt math_sqrt;
  static ecAbs math_abs;
  static ecPow math_pow(&ezExp);
  static const char *math_symtab[] = {"pi", "e", "sin", "cos", "tan", "sinh", "cosh", "tanh", "asin", "acos", "atan", "log", "log10", "sqrt", "abs", "pow", NULL};
  static ezValue *math_constants[] = {&ezPi, &ezExp, &math_sin, &math_cos, &math_tan, &math_sinh, &math_cosh, &math_tanh, &math_asin, &math_acos, &math_atan, &math_log, &math_log10, &math_sqrt, &math_abs, &math_pow, NULL};
  *symtab = (char **)math_symtab;
  *constants = math_constants;
}
