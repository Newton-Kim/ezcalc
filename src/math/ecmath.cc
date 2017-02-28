#include "ecmath.h"

class ecSin: public ezNativeCarousel {
public:
  void run(vector<ezValue*> &args, vector<ezValue*> &rets) {
    rets.clear();
    if(args.empty()) runtime_error("sin function has no argument.");
    switch(args[0]->type) {
    }
    
  }
};

void ecMath::load(char ***symtab, ezValue ***constants) {
  static ezFloat ezPi(M_PI), ezExp(exp(1));
  static ecSin math_sin;
  static const char *math_symtab[] = {"pi", "e", "sin", NULL};
  static ezValue *math_constants[] = {&ezPi, &ezExp, &math_sin, NULL};
  *symtab = (char **)math_symtab;
  *constants = math_constants;
}
