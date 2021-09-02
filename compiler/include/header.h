#include <iostream>
#include <vector>
#include <typeinfo>
#include <algorithm>
#include <sstream>
#include <map>
// #include "./curl/include/curl/curl.h"

std::string __ERROR__;

std::string __tostring(auto val) {
  std::stringstream ss;
  ss << val;
  return ss.str();
}

const char* tocstring(std::string str) {
  return str.c_str();
}

int len(std::string s) {
  return s.length();
}

std::string error(std::string msg) {
  __ERROR__ = msg;
  throw(msg);
}

void fatal(std::string msg) {
  std::cout << "FATAL ERROR: " + msg << std::endl;
  exit(1);
}