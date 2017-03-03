#include "procstack.h"

void ProcStack::pop(void) {
  if (m_proc_stack.empty())
    return;
  ProcStackItem *item = m_proc_stack.top();
  delete item;
  m_proc_stack.pop();
}

void ProcStack::push(ezAsmProcedure *proc) {
  ProcStackItem *item = new ProcStackItem(proc);
  if (m_proc_stack.empty())
    m_entry = item;
  m_proc_stack.push(item);
}

void ProcStack::clear(void) {
  while (!m_proc_stack.empty())
    pop();
}
