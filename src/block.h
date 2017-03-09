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
    ecBlock(ecBlockType tp);
    virtual ~ecBlock(){};
};

class ecBlockDoWhile : public ecBlock {
  private:
    string m_begin;
    string m_end;
  public:
    ecBlockDoWhile(size_t count);
    ~ecBlockDoWhile();
    string label_begin(void) { return m_begin; }
    string label_end(void) { return m_end; }
};

class ecBlockIf : public ecBlock {
  private:
    string m_else;
    string m_end;
  public:
    ecBlockIf(size_t count);
    ecBlockIf(size_t count, string end);
    ~ecBlockIf();
    string label_else(void) { return m_else; }
    string label_end(void) { return m_end; }
};
