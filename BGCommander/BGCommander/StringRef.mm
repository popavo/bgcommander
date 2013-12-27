#import "StringRef.h"
#import <iostream>

BG_NAMESPACE

template<typename _Tp>
_Tp ValidString(_Tp __s);

template<> FORCE_INLINE NSString* ValidString<NSString*>(NSString* __s)                                { return (!__s) ? @"" : __s; }
template<> FORCE_INLINE const char* ValidString<const char*>(const char* __s)                          { return (__s == NULL) ? "" : __s; }
template<> FORCE_INLINE const std::string& ValidString<const std::string&>(const std::string& __s)     { return (__s.c_str() != NULL) ? __s : *(new std::string()); }
template<> FORCE_INLINE const StringRef& ValidString<const StringRef&>(const StringRef& __s)              { return (!__s.fString) ? *(new StringRef()) : __s; }

#define VALID_STR(arg) ValidString<__typeof__(arg)>(arg)

const StringRef& Newline = @"\n";

int StringRef::compare(const StringRef& rs) const {
  if (fString == nullptr) {
    return !!rs;
  }
  if (!fString) {
    return !!rs;
  }

  return [fString compare:rs.fString];
}

void StringRef::zero()                                     { fString = NULL; preAppend = NULL; postAppend = NULL; }

NSString* StringRef::setPreAppend(NSString* rs)            { NSString* oldPreAppend = preAppend; preAppend = rs; return oldPreAppend; }
NSString* StringRef::setPostAppend(NSString* rs)           { NSString* oldPostAppend = postAppend; postAppend = rs; return oldPostAppend; }

StringRef& StringRef::operator =(const StringRef& rs)        { return assign(rs); }
StringRef& StringRef::operator =(NSString* rs)              { return assign(rs); }
StringRef& StringRef::operator =(const_char rs)             { return assign(rs); }
StringRef& StringRef::operator =(StringRef&& rs)             { return _assignMove(rs); }

StringRef& StringRef::operator +=(const StringRef& rs)       { return append(rs); }
StringRef& StringRef::operator +=(NSString* rs)             { return append(rs); }
StringRef& StringRef::operator +=(const_char rs)            { return append(rs); }

StringRef& StringRef::operator +(const StringRef& rs)        { return *this += rs; }
StringRef& StringRef::operator +(NSString* rs)              { return *this += rs; }
StringRef& StringRef::operator +(const_char rs)             { return *this += rs; }

StringRef& StringRef::operator <<(const StringRef& rs)       { return appendString(rs); }
StringRef& StringRef::operator <<(NSString* rs)             { return appendString(rs); }
StringRef& StringRef::operator <<(const_char rs)            { return appendString(rs); }

StringRef::operator NSString*() const                      { return fString; }
StringRef::operator const_char() const                     { return c_str(); }

StringRef::const_char StringRef::c_str() const              { return fString.UTF8String; }

size_t StringRef::size() const                             { return (fString) ? fString.length : 0; }
size_t StringRef::hash() const                             { return fString.hash; }

StringRef& StringRef::assign(NSString* rs)                  { fString = VALID_STR(rs); return *this; }
StringRef& StringRef::assign(const_char rs)                 { fString = @(VALID_STR(rs)); return *this; }

StringRef& StringRef::append(NSString* rs)                  { return append(preAppend, rs, postAppend); }
StringRef& StringRef::append(const_char rs)                 { return append(@(VALID_STR(rs))); }
StringRef& StringRef::append(const StringRef& rs)            { return append(rs.fString); }
StringRef& StringRef::appendString(NSString* rs)            { fString = [fString stringByAppendingString:VALID_STR(rs)]; return *this; }
StringRef& StringRef::appendString(const_char rs)           { return appendString(@(VALID_STR(rs))); }
StringRef& StringRef::appendString(const StringRef& rs)      { return appendString(VALID_STR(rs.fString)); }

StringRef& StringRef::_assignMove(StringRef& rs) {
  fString = std::move(rs.fString);
  preAppend = std::move(rs.preAppend);
  postAppend = std::move(rs.postAppend);
  rs.zero();
  return *this;
}

StringRef& StringRef::assign(const StringRef& rs) {
  if (!rs) {
    fString = preAppend = postAppend = @"";
  } else {
    fString = rs.fString;
    preAppend = rs.preAppend;
    postAppend = rs.postAppend;
  }
  return *this;
}

StringRef& StringRef::appendFormat(const_char format, ...) {
  VA_STR(format, @(format), str)

  return append(VALID_STR(preAppend), VALID_STR(str), VALID_STR(postAppend));
}

StringRef& StringRef::appendFormat(const_char pre, const_char post, const_char format, ...) {
  VA_STR(format, @(format), str)

  return append(@(VALID_STR(pre)), VALID_STR(str), @(VALID_STR(post)));
}

StringRef& StringRef::appendFormat(NSString* format, ...) {
  VA_STR(format, format, str)

  return append(VALID_STR(preAppend), VALID_STR(str), VALID_STR(postAppend));
}

StringRef& StringRef::append(NSString* pre, NSString* str, NSString* post) {
  fString = [fString stringByAppendingFormat:@"%@%@%@", VALID_STR(pre), VALID_STR(str), VALID_STR(post)];
  return *this;
}

StringRef& StringRef::appendFormat(NSString* pre, NSString* post, NSString* format, ...) {
  VA_STR(format, format, str);
  return append(VALID_STR(pre), VALID_STR(str), VALID_STR(post));
}

StringRef& StringRef::appendFormatOnly(const_char format, ...) {
  VA_STR(format, @(format), str)

  fString = [fString stringByAppendingString:VALID_STR(str)];
  return *this;
}

StringRef& StringRef::appendFormatOnly(NSString* format, ...) {
  VA_STR(format, format, str)
  fString = [fString stringByAppendingString:VALID_STR(str)];
  return *this;
}

StringRef& StringRef::addNewline() {
  fString = [fString stringByAppendingString:@"\n"];
  return *this;
}

bool StringRef::is_equal(const StringRef& rs) const                             { return [fString isEqualToString:rs.fString]; }
void StringRef::print() const                                                  { std::cout << *this; }
void StringRef::print(const StringRef& prefix, const StringRef& suffix) const    { std::cout << prefix << *this << suffix; }

BG_NAMESPACE_END

@implementation NSArray (StringVector)

+(NSArray*) stringsFromStringVector:(const bg::StringVector*)stringVector {
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

-(bg::StringVector) stringVector {
  bg::StringVector strings;
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