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
    string m_begin;
    string m_end;
  public:
    ecBlockDoWhile(size_t count):ecBlock(EC_BLOCK_TYPE_DO_WHILE){
      {
      stringstream ss;
      ss << "L_while_begin_" << count;
      m_begin = ss.str();
      }
      {
      stringstream ss;
      ss << "L_while_end_" << count;
      m_end = ss.str();
      }
    }
    ~ecBlockDoWhile() {}
    string begin(void) { return m_begin; }
    string end(void) { return m_end; }
};
