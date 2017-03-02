#include "ecmath.h"
#include <functional>

inline void mathf_1arg(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets, function<ezValue *(ezValue*)> func) {
  rets.clear();
  if(args.empty()) runtime_error("sin function has no argument.");
  switch(args[0]->type) {
    case EZ_VALUE_TYPE_INTEGER:
    case EZ_VALUE_TYPE_FLOAT:
      rets.push_back((ezValue*)gc.add((ezGCObject*) func(args[0])));
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
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(sin(arg->to_float()));});
  }
};

class ecCos: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(cos(arg->to_float()));});
  }
};

class ecTan: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(tan(arg->to_float()));});
  }
};

class ecSinh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(sin(arg->to_float()));});
  }
};

class ecCosh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(cos(arg->to_float()));});
  }
};

class ecTanh: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(tan(arg->to_float()));});
  }
};

class ecAsin: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(asin(arg->to_float()));});
  }
};

class ecAcos: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(acos(arg->to_float()));});
  }
};

class ecAtan: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(atan(arg->to_float()));});
  }
};

class ecLog10: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(log10(arg->to_float()));});
  }
};

class ecLog: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {return new ezFloat(log(arg->to_float()));});
  }
};

class ecSqrt: public ezNativeCarousel {
public:
  void run(ezGC& gc, vector<ezValue*> &args, vector<ezValue*> &rets) {
    mathf_1arg(gc, args, rets, [](ezValue* arg) {
      double v = arg->to_float();
      return (v >= 0) ? (ezValue*)new ezFloat(sqrt(v)) : (ezValue*)new ezComplex(complex<double>(0, sqrt(-v)));
    });
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
  static const char *math_symtab[] = {"pi", "e", "sin", "cos", "tan", "sinh", "cosh", "tanh", "asin", "acos", "atan", "log", "log10", "sqrt", "abs", NULL};
  static ezValue *math_constants[] = {&ezPi, &ezExp, &math_sin, &math_cos, &math_tan, &math_sinh, &math_cosh, &math_tanh, &math_asin, &math_acos, &math_atan, &math_log, &math_log10, &math_sqrt, &math_abs, NULL};
  *symtab = (char **)math_symtab;
  *constants = math_constants;
}
