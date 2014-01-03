#ifndef __BG_OPTION_H__
#define __BG_OPTION_H__

#import <vector>
#import <algorithm>
#import <BGCommander.h>

BG_NAMESPACE

class OptionDefinitionVector : public std::vector<GBOptionDefinition> {
public:
  OptionDefinitionVector() : std::vector<GBOptionDefinition>() { }
  OptionDefinitionVector(std::initializer_list<value_type> __il) : std::vector<GBOptionDefinition>(__il) { }

  bool contains(const_reference rs)       { return std::find(cbegin(), cend(), rs) != cend(); }
  void add(const_reference rs)            { push_back(rs); }
  iterator remove(const_reference rs)     { return erase(std::remove(begin(), end(), rs), end()); }
  iterator remove(size_type rs)           { if (rs >= size()) return end(); return remove(at(rs)); }

  reference find(char _so=0, NSString* _lo=nil) {
    for (auto & optionDef:*this) {
      if ((optionDef.shortOption == _so) && [optionDef.longOption isEqualToString:_lo]) {
        return optionDef;
      }
    }
    return *end();
  }

  StringRef helpString(int leadingWhiteSpace = 4) {
    StringRef help;
    if (size()) {
      GBOptionsHelper* helper = [GBOptionsHelper new];
      [helper registerOptionsFromDefinitions:this->data() count:this->size()];
      help += [helper helpStringWithLeadingSpaces:leadingWhiteSpace];
    }
    return help;
  }
};

BG_NAMESPACE_END

#endif