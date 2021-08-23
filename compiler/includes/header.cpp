#include <iostream>
#include <vector>
#include <typeinfo>
#include <algorithm>
#include <sstream>
#include <map>

std::string __ERROR__;

std::string tostring(auto s) {
  std::stringstream ss;
  ss << s;
  return ss.str();
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