#include "block.h"

ecBlock::ecBlock(ecBlockType tp):type(tp){}

ecBlockDoWhile::ecBlockDoWhile(size_t count):ecBlock(EC_BLOCK_TYPE_DO_WHILE){
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

ecBlockDoWhile::~ecBlockDoWhile(){ }

ecBlockIf::ecBlockIf(size_t count):ecBlock(EC_BLOCK_TYPE_DO_WHILE){
      {
      stringstream ss;
      ss << "L_if_else_" << count;
      m_else = ss.str();
      }
      {
      stringstream ss;
      ss << "L_if_end_" << count;
      m_end = ss.str();
      }
}

ecBlockIf::ecBlockIf(size_t count, string end):ecBlock(EC_BLOCK_TYPE_DO_WHILE), m_end(end) {
      stringstream ss;
      ss << "L_if_else_" << count;
      m_else = ss.str();
}

ecBlockIf::~ecBlockIf(){ }
