#include <iostream>
#include <vector>
#include <typeinfo>
#include <algorithm>
#include <map>

std::string __ERROR__;

std::string tostring(auto s) {
  return std::to_string(s);
}

int len(std::string s) {
  return s.length();
}

std::string tostring(bool b) {
  return b ? "true" : "false";
}

std::string tostring(char c) {
  std::string s; s.push_back(c); return s;
}

std::string error(std::string msg) {
  __ERROR__ = msg;
  throw(msg);
}

void fatal(std::string msg) {
  std::cout << "FATAL ERROR: " + msg << std::endl;
  exit(1);
}