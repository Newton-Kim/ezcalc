#include "ecmath.h"
#include <functional>

inline void mathf_1arg(vector<ezValue *> &args, vector<ezValue *> &rets,
                       function<ezValue *(ezInteger *)> funci,
                       function<ezValue *(ezFloat *)> funcf,
                       function<ezValue *(ezComplex *)> funcc) {
  rets.clear();
  if (args.empty())
    runtime_error("sin function has no argument.");
  switch (args[0]->type) {
  case EZ_VALUE_TYPE_INTEGER:
    rets.push_back(funci((ezInteger*)args[0]));
    break;
  case EZ_VALUE_TYPE_FLOAT:
    rets.push_back(funcf((ezFloat*)args[0]));
    break;
  case EZ_VALUE_TYPE_COMPLEX:
    rets.push_back(funcc((ezComplex*)args[0]));
    break;
  default:
    rets.push_back(ezNull::instance());
    rets.push_back(new ezString("invalid argument type"));
    break;
  }
}

class ecSin : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(sin(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(sin(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(sin(arg->value)); });
  }
};

class ecCos : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(cos(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(cos(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(cos(arg->value)); });
  }
};

class ecTan : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(tan(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(tan(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(tan(arg->value)); });
  }
};

class ecSinh : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(sinh(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(sinh(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(sinh(arg->value)); });
  }
};

class ecCosh : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(cosh(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(cosh(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(cosh(arg->value)); });
  }
};

class ecTanh : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(tanh(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(tanh(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(tanh(arg->value)); });
  }
};

class ecAsin : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(asin(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(asin(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(asin(arg->value)); });
  }
};

class ecAcos : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(acos(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(acos(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(acos(arg->value)); });
  }
};

class ecAtan : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(atan(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(atan(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(atan(arg->value)); });
  }
};

class ecLog10 : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(log10(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(log10(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(log10(arg->value)); });
  }
};

class ecLog : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) { return new ezInteger(log(arg->value)); },
        [](ezFloat *arg) { return new ezFloat(log(arg->value)); },
        [](ezComplex *arg) { return new ezComplex(log(arg->value)); });
  }
};

class ecSqrt : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    mathf_1arg(
        args, rets,
        [](ezInteger *arg) {
          double v = arg->value;
          return (v >= 0)
                     ? (ezValue *)new ezFloat(sqrt(v))
                     : (ezValue *)new ezComplex(complex<double>(0, sqrt(-v)));
        },
        [](ezFloat *arg) {
          double v = arg->value;
          return (v >= 0)
                     ? (ezValue *)new ezFloat(sqrt(v))
                     : (ezValue *)new ezComplex(complex<double>(0, sqrt(-v)));
        },
        [](ezComplex *arg) { return new ezComplex(sqrt(arg->value)); });
  }
};

class ecAbs : public ezUserDefinedFunction {
public:
  void run(vector<ezValue *> &args, vector<ezValue *> &rets) {
    rets.clear();
    if (args.empty())
      runtime_error("sin function has no argument.");
    switch (args[0]->type) {
    case EZ_VALUE_TYPE_INTEGER: {
      int v = ((ezInteger*)args[0])->value;
      rets.push_back(new ezInteger(v > 0 ? v : -v));
    } break;
    case EZ_VALUE_TYPE_FLOAT: {
      double v = ((ezFloat*)args[0])->value;
      rets.push_back(new ezFloat(v > 0 ? v : -v));
    } break;
    case EZ_VALUE_TYPE_COMPLEX: {
      complex<double> v = ((ezComplex*)args[0])->value;
      rets.push_back(new ezFloat(abs(v)));
    } break;
    default:
      rets.push_back(ezNull::instance());
      rets.push_back(new ezString("invalid argument type"));
      break;
    }
  }
};

ezIntrinsicTable *ecMath::load(void) {
  static ezNull *ezNull = ezNull::instance();
  static ezFloat *ezPi = new ezFloat(M_PI), *ezExp = new ezFloat(exp(1));
  static ecSin *math_sin = new ecSin;
  static ecCos *math_cos = new ecCos;
  static ecTan *math_tan = new ecTan;
  static ecSinh *math_sinh = new ecSinh;
  static ecCosh *math_cosh = new ecCosh;
  static ecTanh *math_tanh = new ecTanh;
  static ecAsin *math_asin = new ecAsin;
  static ecAcos *math_acos = new ecAcos;
  static ecAtan *math_atan = new ecAtan;
  static ecLog *math_log = new ecLog;
  static ecLog10 *math_log10 = new ecLog10;
  static ecSqrt *math_sqrt = new ecSqrt;
  static ecAbs *math_abs = new ecAbs;
  static ezIntrinsicTable math_symtab[] = {
      {"null", ezNull},
      {"pi", ezPi},
      {"e", ezExp},
      {"sin", math_sin},
      {"cos", math_cos},
      {"tan", math_tan},
      {"sinh", math_sinh},
      {"cosh", math_cosh},
      {"tanh", math_tanh},
      {"asin", math_asin},
      {"acos", math_acos},
      {"atan", math_atan},
      {"log", math_log},
      {"log10", math_log10},
      {"sqrt", math_sqrt},
      {"abs", math_abs},
      {NULL, NULL}
  };
  return math_symtab;
}
