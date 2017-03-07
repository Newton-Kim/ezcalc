#pragma once

#include <string>
#include <sstream>

using namespace std;

enum ecBlockType {
  EC_BLOCK_TYPE_IF,
  EC_BLOCK_TYPE_DO_WHILE,
  EC_BLOCK_TYPE_WHILE,
  EC_BLOCK_TYPE_FOR
};

class ecBlock {
  public:
    const ecBlockType type;
    ecBlock(ecBlockType tp):type(tp){}
    virtual ~ecBlock(){};
};

class ecBlockDoWhile : public ecBlock {
  private:
    string m_label;
  public:
    ecBlockDoWhile():ecBlock(EC_BLOCK_TYPE_DO_WHILE){
      stringstream ss;
      ss << "L_do" << (void*)this;
      m_label = ss.str();
    }
    ~ecBlockDoWhile() {}
    string label(void) { return m_label; }
};
