#import "BGString.h"
#import "BGCommanderHelpers.h"
#import <iostream>

template<typename _Tp>
_Tp ValidString(_Tp __s);

template<> FORCE_INLINE NSString* ValidString<NSString*>(NSString* __s)                                { return (!__s) ? @"" : __s; }
template<> FORCE_INLINE const char* ValidString<const char*>(const char* __s)                          { return (__s == NULL) ? "" : __s; }
template<> FORCE_INLINE const std::string& ValidString<const std::string&>(const std::string& __s)     { return (__s.c_str() != NULL) ? __s : *(new std::string()); }
template<> FORCE_INLINE const BGString& ValidString<const BGString&>(const BGString& __s)              { return (!__s.fString) ? *(new BGString()) : __s; }

#define VALID_STR(arg) ValidString<__typeof__(arg)>(arg)

const BGString& Newline = @"\n";

int BGString::compare(const BGString& rs) const {
  if (fString == nullptr) {
    return !!rs;
  }
  if (!fString) {
    return !!rs;
  }

  return [fString compare:rs.fString];
}

void BGString::zero()                                     { fString = NULL; preAppend = NULL; postAppend = NULL; }

NSString* BGString::setPreAppend(NSString* rs)            { NSString* oldPreAppend = preAppend; preAppend = rs; return oldPreAppend; }
NSString* BGString::setPostAppend(NSString* rs)           { NSString* oldPostAppend = postAppend; postAppend = rs; return oldPostAppend; }

BGString& BGString::operator =(const BGString& rs)        { return assign(rs); }
BGString& BGString::operator =(NSString* rs)              { return assign(rs); }
BGString& BGString::operator =(const_char rs)             { return assign(rs); }
BGString& BGString::operator =(BGString&& rs)             { return _assignMove(rs); }

BGString& BGString::operator +=(const BGString& rs)       { return append(rs); }
BGString& BGString::operator +=(NSString* rs)             { return append(rs); }
BGString& BGString::operator +=(const_char rs)            { return append(rs); }

BGString& BGString::operator +(const BGString& rs)        { return *this += rs; }
BGString& BGString::operator +(NSString* rs)              { return *this += rs; }
BGString& BGString::operator +(const_char rs)             { return *this += rs; }

BGString& BGString::operator <<(const BGString& rs)       { return appendString(rs); }
BGString& BGString::operator <<(NSString* rs)             { return appendString(rs); }
BGString& BGString::operator <<(const_char rs)            { return appendString(rs); }

BGString::operator NSString*() const                      { return fString; }
BGString::operator const_char() const                     { return c_str(); }

BGString::const_char BGString::c_str() const              { return fString.UTF8String; }

size_t BGString::size() const                             { return (fString) ? fString.length : 0; }
size_t BGString::hash() const                             { return fString.hash; }

BGString& BGString::assign(NSString* rs)                  { fString = VALID_STR(rs); return *this; }
BGString& BGString::assign(const_char rs)                 { fString = @(VALID_STR(rs)); return *this; }

BGString& BGString::append(NSString* rs)                  { return append(preAppend, rs, postAppend); }
BGString& BGString::append(const_char rs)                 { return append(@(VALID_STR(rs))); }
BGString& BGString::append(const BGString& rs)            { return append(rs.fString); }
BGString& BGString::appendString(NSString* rs)            { fString = [fString stringByAppendingString:VALID_STR(rs)]; return *this; }
BGString& BGString::appendString(const_char rs)           { return appendString(@(VALID_STR(rs))); }
BGString& BGString::appendString(const BGString& rs)      { return appendString(VALID_STR(rs.fString)); }

BGString& BGString::_assignMove(BGString& rs) {
  fString = std::move(rs.fString);
  preAppend = std::move(rs.preAppend);
  postAppend = std::move(rs.postAppend);
  rs.zero();
  return *this;
}

BGString& BGString::assign(const BGString& rs) {
  if (!rs) {
    fString = preAppend = postAppend = @"";
  } else {
    fString = rs.fString;
    preAppend = rs.preAppend;
    postAppend = rs.postAppend;
  }
  return *this;
}

BGString& BGString::appendFormat(const_char format, ...) {
  VA_STR(format, @(format), str)

  return append(VALID_STR(preAppend), VALID_STR(str), VALID_STR(postAppend));
}

BGString& BGString::appendFormat(const_char pre, const_char post, const_char format, ...) {
  VA_STR(format, @(format), str)

  return append(@(VALID_STR(pre)), VALID_STR(str), @(VALID_STR(post)));
}

BGString& BGString::appendFormat(NSString* format, ...) {
  VA_STR(format, format, str)

  return append(VALID_STR(preAppend), VALID_STR(str), VALID_STR(postAppend));
}

BGString& BGString::append(NSString* pre, NSString* str, NSString* post) {
  fString = [fString stringByAppendingFormat:@"%@%@%@", VALID_STR(pre), VALID_STR(str), VALID_STR(post)];
  return *this;
}

BGString& BGString::appendFormat(NSString* pre, NSString* post, NSString* format, ...) {
  VA_STR(format, format, str);
  return append(VALID_STR(pre), VALID_STR(str), VALID_STR(post));
}

BGString& BGString::appendFormatOnly(const_char format, ...) {
  VA_STR(format, @(format), str)

  fString = [fString stringByAppendingString:VALID_STR(str)];
  return *this;
}

BGString& BGString::appendFormatOnly(NSString* format, ...) {
  VA_STR(format, format, str)
  fString = [fString stringByAppendingString:VALID_STR(str)];
  return *this;
}

BGString& BGString::addNewline() {
  fString = [fString stringByAppendingString:@"\n"];
  return *this;
}

bool BGString::is_equal(const BGString& rs) const                             { return [fString isEqualToString:rs.fString]; }
void BGString::print() const                                                  { std::cout << *this; }
void BGString::print(const BGString& prefix, const BGString& suffix) const    { std::cout << prefix << *this << suffix; }

@implementation NSArray (BGStringVector)

+(NSArray*) stringsFromStringVector:(const BGStringVector*)stringVector {
  if (stringVector->empty()) {
    return @[];
  }
  
  NSMutableArray* strings = [NSMutableArray new];

  for (auto const& str:*stringVector) {
    NSString* s = str.fString;
    if (s) [strings addObject:s];
  }

  return [strings copy];
}

-(BGStringVector) stringVector {
  BGStringVector strings;
  strings.reserve(self.count);
  for (NSUInteger i = 0; i < self.count; i++) {
    NSString* str = [self objectAtIndex:i];
    if ([str isKindOfClass:[NSString class]]) {
      strings.push_back(str);
    }
  }
  return strings;
}

@end