#pragma once

#include <ezvm/ezvm.h>

class ProcStack {
private:
  class ProcStackItem {
   public:
    ezAsmProcedure* m_proc;
    vector <ezAddress> m_args;
    vector <ezAddress> m_addrs;
    size_t m_local;
    size_t m_temp;
    size_t m_temp_max;
   public:
    ProcStackItem(ezAsmProcedure* proc) : m_proc(proc), m_local(0), m_temp(0) {}
    ~ProcStackItem() { m_proc->grow(m_local + m_temp_max); }
    size_t inc_temp(void) {
      m_temp++;
      if (m_temp_max < m_temp) m_temp_max = m_temp;
      return m_temp - 1;
    }
    size_t inc_local(void) { return m_local++;}
    void reset_temp(void) { m_temp = m_local;}
  };
  ProcStackItem* m_entry;
  stack<ProcStackItem*> m_proc_stack;
public:
  ProcStack() : m_entry(NULL){}
  ~ProcStack() {clear();}
  ezAsmProcedure* func(void) {return m_proc_stack.top()->m_proc;}
  void pop(void);
  void push(ezAsmProcedure* proc);
  void clear(void);
  bool is_entry(void){ return m_proc_stack.top() == m_entry; }
  vector <ezAddress>& args(void) {return m_proc_stack.top()->m_args;}
  vector <ezAddress>& addrs(void) {return m_proc_stack.top()->m_addrs;}
  size_t inc_temp(void) { return m_proc_stack.top()->inc_temp();}
  size_t inc_local(void) { return m_proc_stack.top()->inc_local();}
  void reset_temp(void) { m_proc_stack.top()->reset_temp();}
};
