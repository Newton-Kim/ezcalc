#pragma once

#include "block.h"
#include <ezvm/ezvm.h>

class ProcStack {
private:
  class ProcStackItem {
  public:
    ezAsmProcedure *m_proc;
    stack<vector<ezAddress>> m_args;
    stack<vector<ezAddress>> m_addrs;
    stack<ecBlock *> m_blocks;
    stack<ezAsmInstruction *> m_instrs;
    size_t m_local;
    size_t m_temp;
    size_t m_temp_max;

  public:
    ProcStackItem(ezAsmProcedure *proc)
        : m_proc(proc), m_local(0), m_temp(0), m_temp_max(0) {
      m_instrs.push(new ezAsmInstruction);
    }
    ~ProcStackItem() {
      if(!m_instrs.empty()) {
        ezAsmInstruction *instr = m_instrs.top();
        m_proc->append_instruction(instr);
        m_instrs.pop();
      }
      m_proc->mems(m_local + m_temp_max);
    }
    size_t inc_temp(void) {
      m_temp++;
      if (m_temp_max < m_temp)
        m_temp_max = m_temp;
      return m_temp - 1;
    }
    void set_local(size_t local) { if (m_local < local) m_local = local; }
    void reset_temp(void) { m_temp = m_local; }
  };
  ProcStackItem *m_entry;
  stack<ProcStackItem *> m_proc_stack;

public:
  ProcStack() : m_entry(NULL) {}
  ~ProcStack() { clear(); }
  ezAsmProcedure *func(void) { return m_proc_stack.top()->m_proc; }
  stack<ezAsmInstruction *> &instr(void) { return m_proc_stack.top()->m_instrs; }
  void pop(void);
  void push(ezAsmProcedure *proc);
  void clear(void);
  bool is_entry(void) { return m_proc_stack.top() == m_entry; }
  stack<vector<ezAddress>> &args(void) { return m_proc_stack.top()->m_args; }
  stack<vector<ezAddress>> &addrs(void) { return m_proc_stack.top()->m_addrs; }
  stack<ecBlock *> &blocks(void) { return m_proc_stack.top()->m_blocks; }
  size_t inc_temp(void) { return m_proc_stack.top()->inc_temp(); }
  void set_local(size_t local) { m_proc_stack.top()->set_local(local); }
  void reset_temp(void) { m_proc_stack.top()->reset_temp(); }
};
