#ifndef __BG_STRING_H__
#define __BG_STRING_H__

#import <string>
#import <iostream>
#import <vector>
#import "BGCommander.h"

BG_NAMESPACE

class StringRef;

extern const StringRef& Newline;

class StringRef {
public:
  typedef const char* const_char;

  NSString* fString;
  NSString* preAppend;
  NSString* postAppend;

  StringRef() : fString(@""), preAppend(@""), postAppend(@"") { }
  StringRef(const StringRef& rs) : fString(rs.fString), preAppend(@""), postAppend(@"") { }
  StringRef(NSString* rs) : fString(rs), preAppend(@""), postAppend(@"") { }
  StringRef(const_char rs) { preAppend = @""; postAppend = @""; assign(rs); }
  StringRef(StringRef&& rs) { _assignMove(rs); }

  void zero();

  NSString* setPreAppend(NSString* rs);
  NSString* setPostAppend(NSString* rs);

  StringRef& operator =(const StringRef& rs);
  StringRef& operator =(NSString* rs);
  StringRef& operator =(const_char rs);
  StringRef& operator =(StringRef&& rs);

  StringRef& operator +=(const StringRef& rs);
  StringRef& operator +=(NSString* rs);
  StringRef& operator +=(const_char rs);

  StringRef& operator +(const StringRef& rs);
  StringRef& operator +(NSString* rs);
  StringRef& operator +(const_char rs);

  StringRef& operator <<(const StringRef& rs);
  StringRef& operator <<(NSString* rs);
  StringRef& operator <<(const_char rs);

  operator NSString*() const;
  operator const_char() const;

  const_char c_str() const;
  
  size_t size() const;
  size_t hash() const;

  EQ_OPERATOR(const StringRef&, [fString isEqualToString:rs.fString])
  EQ_OPERATOR(NSString*, [fString isEqualToString:rs])
  EQ_OPERATOR(const_char, [fString isEqualToString:@(rs)])
  bool operator !() const { return fString == nil || fString == Nil || fString == NULL || fString.length == 0; }
  bool valid() const { return !!*this; }

  StringRef& assign(NSString* rs);
  StringRef& assign(const_char rs);
  StringRef& assign(const StringRef& rs);

  StringRef& append(NSString* rs);
  StringRef& append(const_char rs);
  StringRef& append(const StringRef& rs);
  StringRef& appendString(NSString* rs);
  StringRef& appendString(const_char rs);
  StringRef& appendString(const StringRef& rs);

  StringRef& appendFormat(const_char format, ...) CHAR_FORMAT_FUNCTION(2,3);
  StringRef& appendFormat(NSString* format, ...) NS_FORMAT_FUNCTION(2, 3);

  StringRef& append(NSString* pre, NSString* str, NSString* post);
  StringRef& appendFormat(NSString* pre, NSString* post, NSString* format, ...) NS_FORMAT_FUNCTION(4,5);
  StringRef& appendFormat(const_char pre, const_char post, const_char format, ...) CHAR_FORMAT_FUNCTION(4,5);

  StringRef& appendFormatOnly(const_char format, ...) CHAR_FORMAT_FUNCTION(2,3);
  StringRef& appendFormatOnly(NSString* format, ...) NS_FORMAT_FUNCTION(2, 3);

  StringRef& addNewline();

  int compare(const StringRef& rs) const;
  bool is_equal(const StringRef& rs) const;

  void print() const;
  void print(const StringRef& prefix, const StringRef& suffix) const;

private:
  StringRef& _assignMove(StringRef& rs);
};

class StringVector : public std::vector<StringRef> {
public:
  StringVector() : std::vector<StringRef>() { }
  StringVector(std::initializer_list<value_type> __il) : std::vector<StringRef>(__il) { }
  void add(const_reference rs)            { push_back(rs); }
  void add(value_type&& rs)               { push_back(std::move(rs)); }
};

inline std::ostream& operator <<(std::ostream& OS, const bg::StringRef& string) {
  OS << string.c_str();
  return OS;
}

inline std::ostream& operator <<(std::ostream& OS, const bg::StringVector& strings) {
  for (auto const& str:strings) {
    OS << str;
    if (str != *--strings.cend()) {
      OS << std::endl;
    }
  }
  return OS;
}

BG_NAMESPACE_END

@interface NSArray (StringVector)

+(NSArray*)stringsFromStringVector:(const bg::StringVector*)strings;
-(bg::StringVector)stringVector;

@end

#endif