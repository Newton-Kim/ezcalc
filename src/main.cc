#include <ezvm/ezvm.h>
#include <getopt.h>
#include <iostream>
using namespace std;
#define VERSION "1.0.0"

extern void run_it(void);
extern void run_it(string source);

void show_help(const char *name) {
  cout << name << " version " << VERSION << endl;
  cout << "Usage: " << name << " [option]... asm_file" << endl;
  cout << "Option:" << endl;
  cout << "  -h, --help  shows this screen" << endl;
  cout << "  -v, --version  prints the version" << endl;
}

int main(int argc, char *argv[]) {
  string source;
  int c, option_index;
  bool help_flag = false, version_flag = false;
  struct option long_options[] = {{"help", no_argument, 0, 'h'},
                                  {"version", no_argument, 0, 'v'},
                                  {0, 0, 0, 0}};
  while (1) {
    c = getopt_long(argc, argv, "hvc:l:d:", long_options, &option_index);
    if (c == -1)
      break;
    switch (c) {
    case 'h':
      help_flag = true;
      break;
    case 'v':
      version_flag = true;
      break;
    default:
      cerr << "invalid argument" << (char)c << endl;
      return 1;
      break;
    }
  }
  if (help_flag)
    show_help(argv[0]);
  if (version_flag)
    cout << VERSION << endl;

  while (optind < argc)
    source = argv[optind++];

  if (source.empty())
    run_it();
  else
    run_it(source);
  return 0;
}
