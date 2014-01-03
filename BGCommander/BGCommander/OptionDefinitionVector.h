#ifndef __BG_OPTION_H__
#define __BG_OPTION_H__

#import <vector>
#import <algorithm>
#import "BGCommander.h"

BG_NAMESPACE

class OptionDefinition {
public:
  char shortOption;
  StringRef longOption;
  StringRef description;
  GBOptionFlags flags;

  OptionDefinition(char _so=0, StringRef _lo=@"", StringRef _d=@"", GBOptionFlags _f=0) : shortOption(_so), longOption(_lo), description(_d), flags(_f) { }

  OptionDefinition(const OptionDefinition& rs)                      { _copy(rs); }
  OptionDefinition(OptionDefinition&& rs)                           { _move(std::move(rs)); rs.clear(); }

  OptionDefinition& operator=(const OptionDefinition& rs)           { _copy(rs); return *this; }
  OptionDefinition& operator=(OptionDefinition&& rs)                { _move(std::move(rs)); rs.clear(); return *this; }

  void clear()                                                      { shortOption = 0; longOption.zero(); description.zero(); flags = 0; }

  bool operator ==(const OptionDefinition& rs) const  {
    if (!*this || !rs) return false;
    if (this == &rs) return true;
    bool so = shortOption == rs.shortOption;
    bool lo = (!longOption && !rs.longOption) || longOption == rs.longOption;
    bool d = (!description && !rs.description) || description == rs.description;
    bool f = flags == rs.flags;
    return (so && lo && d && f);
  }

  bool operator !=(const OptionDefinition& rs) const                { return !(*this == rs); }
  bool operator !() const                                           { return (!shortOption && !longOption && !description); }

  NSUInteger requirements() const                                   { return (flags & 0b11); }
  bool isSeparator() const                                          { return ((flags & GBOptionSeparator) > 0); }
  bool isCmdLine() const                                            { return ((flags & GBOptionNoCmdLine) == 0); }
  bool canPrintSettings() const                                     { return ((flags & GBOptionNoPrint) == 0); }
  bool includeInHelp() const                                        { return ((flags & GBOptionNoHelp) == 0); }

private:
  void _copy(const OptionDefinition& rs) {
    shortOption = rs.shortOption; longOption = rs.longOption;
    description = rs.description; flags = rs.flags;
  }
  void _move(OptionDefinition&& rs) {
    shortOption = std::move(rs.shortOption); longOption = std::move(rs.longOption);
    description = std::move(rs.description); flags = std::move(rs.flags);
  }
};

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