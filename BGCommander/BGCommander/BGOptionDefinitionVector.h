#ifndef __BG_OPTION_H__
#define __BG_OPTION_H__

#import <vector>
#import <algorithm>
#import "BGString.h"
#import "BGCommanderHelpers.h"

class BGOptionDefinitionVector : public std::vector<GBOptionDefinition> {
public:
  BGOptionDefinitionVector() : std::vector<GBOptionDefinition>() { }
  BGOptionDefinitionVector(std::initializer_list<value_type> __il) : std::vector<GBOptionDefinition>(__il) { }

  bool contains(const_reference rs)       { return std::find(cbegin(), cend(), rs) != cend(); }
  void add(const_reference rs)            { push_back(rs); }
  iterator remove(const_reference rs)     { return erase(std::remove(begin(), end(), rs), end()); }
  iterator remove(size_type rs)           { if (rs >= size()) return end(); return remove(at(rs)); }

  BGString helpString(int leadingWhiteSpace = 4) {
    BGString help;
    if (size()) {
      GBOptionsHelper* helper = [GBOptionsHelper new];
      [helper registerOptionsFromDefinitions:this->data() count:this->size()];
      help += [helper helpStringWithLeadingSpaces:leadingWhiteSpace];
    }
    return help;
  }
};

namespace std {
  template<>
  struct hash<BGOptionDefinitionVector::iterator> {
    size_t operator()(const BGOptionDefinitionVector::iterator& __v) {
      hash<GBOptionDefinition> hasher;
      return hasher(*__v);
    }
  };
}

#endif