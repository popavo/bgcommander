#ifndef __BG_STRING_H__
#define __BG_STRING_H__

#import <string>
#import <iostream>
#import "BGCommanderDefines.h"

class BGString;

extern const BGString& Newline;

class BGString {
public:
  typedef const char* const_char;

  NSString* fString;
  NSString* preAppend;
  NSString* postAppend;

  BGString() : fString(@""), preAppend(@""), postAppend(@"") { }
  BGString(const BGString& rs) : fString(rs.fString), preAppend(@""), postAppend(@"") { }
  BGString(NSString* rs) : fString(rs), preAppend(@""), postAppend(@"") { }
  BGString(const_char rs) { preAppend = @""; postAppend = @""; assign(rs); }
  BGString(BGString&& rs) : fString(std::move(rs.fString)), preAppend(std::move(rs.preAppend)), postAppend(std::move(rs.postAppend)) { rs.zero(); }

  void zero();

  NSString* setPreAppend(NSString* rs);
  NSString* setPostAppend(NSString* rs);

  BGString& operator =(const BGString& rs);
  BGString& operator =(NSString* rs);
  BGString& operator =(const_char rs);
  BGString& operator =(BGString&& rs);

  BGString& operator +=(const BGString& rs);
  BGString& operator +=(NSString* rs);
  BGString& operator +=(const_char rs);

  BGString& operator +(const BGString& rs);
  BGString& operator +(NSString* rs);
  BGString& operator +(const_char rs);

  BGString& operator <<(const BGString& rs);
  BGString& operator <<(NSString* rs);
  BGString& operator <<(const_char rs);

  operator NSString*() const;
  operator const_char() const;

  const_char c_str() const;
  
  size_t size() const;
  size_t hash() const;

  EQ_OPERATOR(const BGString&, [fString isEqualToString:rs.fString])
  EQ_OPERATOR(NSString*, [fString isEqualToString:rs])
  EQ_OPERATOR(const_char, [fString isEqualToString:@(rs)])
  bool operator !() const { return fString == nil || fString == Nil || fString == NULL || fString.length == 0; }
  bool valid() const { return !!*this; }

  BGString& assign(NSString* rs);
  BGString& assign(const_char rs);
  BGString& assign(const BGString& rs);

  BGString& append(NSString* rs);
  BGString& append(const_char rs);
  BGString& append(const BGString& rs);
  BGString& appendString(NSString* rs);
  BGString& appendString(const_char rs);
  BGString& appendString(const BGString& rs);

  BGString& appendFormat(const_char format, ...) CHAR_FORMAT_FUNCTION(2,3);
  BGString& appendFormat(NSString* format, ...) NS_FORMAT_FUNCTION(2, 3);

  BGString& append(NSString* pre, NSString* str, NSString* post);
  BGString& appendFormat(NSString* pre, NSString* post, NSString* format, ...) NS_FORMAT_FUNCTION(4,5);
  BGString& appendFormat(const_char pre, const_char post, const_char format, ...) CHAR_FORMAT_FUNCTION(4,5);

  BGString& appendFormatOnly(const_char format, ...) CHAR_FORMAT_FUNCTION(2,3);
  BGString& appendFormatOnly(NSString* format, ...) NS_FORMAT_FUNCTION(2, 3);

  BGString& addNewline();

  int compare(const BGString& rs) const;
  bool is_equal(const BGString& rs) const;

  void print() const;
  void print(const BGString& prefix, const BGString& suffix) const;

private:
  BGString& _assignMove(BGString& rs);
};

inline std::ostream& operator <<(std::ostream& OS, const BGString& string) {
  OS << string.c_str();
  return OS;
}



template <>
struct std::hash<BGString> {
  size_t operator()(const BGString& __v) const {
    return __v.hash();
  }
};

#import <vector>

typedef std::vector<BGString> BGStringVector;

inline std::ostream& operator <<(std::ostream& OS, const BGStringVector& strings) {
  for (auto const& str:strings) {
    OS << str;
    if (str != *--strings.cend()) {
      OS << std::endl;
    }
  }
  return OS;
}

@interface NSArray (BGStringVector)

+(NSArray*)stringsFromStringVector:(const BGStringVector*)strings;
-(BGStringVector)stringVector;

@end

#endif