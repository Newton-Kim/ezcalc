/* 
* Copyright (C) 2015 
* 
* Company  Nuance
*          All rights reserved
* 
* Author   Sung-Hwan Kim (Sung-Hwan.Kim@nuance.com)
* 
* This program is free software; you can redistribute it and/or
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
* ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
* CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
*/
#pragma once
#include "ezvm/ezval.h"

class ecMath{
public:
  static void load(char ***symtab, ezValue ***constants);
};
