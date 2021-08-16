#include <iostream>
#include <vector>
#include <typeinfo>
#include <algorithm>

std::string __ERROR__;

std::string tostring(auto s) {
  return std::to_string(s);
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