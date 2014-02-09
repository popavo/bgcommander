#import "BGCommander.h"
#import <sysexits.h>

typedef NS_ENUM(int, CommanderExits) {
  NO_EXIT = INT32_MIN,

};

#define VA_STR(__format, __formatArg, __name) \
  va_list __ap; \
  va_start(__ap, __format); \
  NSString* __name = [[NSString alloc] initWithFormat:__formatArg arguments:__ap]; \
  va_end(__ap); \

FORCE_INLINE void die(int val, NSString* format, ...) NS_FORMAT_FUNCTION(2, 3) NO_RETURN {
  VA_STR(format, format, print);
  fprintf(stderr, "%s\n", print.UTF8String);
  exit(val);
}

FORCE_INLINE void die(NSString* format, ...) NS_FORMAT_FUNCTION(1, 2) NO_RETURN {
  VA_STR(format, format, print);
  die(EX_SOFTWARE, @"%@", print);
}

template <typename _Tp>
class BGRef {
public:
  typedef _Tp& (^get_block)(_Tp& value);
  typedef _Tp& (^set_block)(_Tp& ref, const _Tp& value);

  BGRef(_Tp ref = nil, get_block _g = NULL, set_block _s=NULL) : getter(_g), setter(_s) { set(ref); }

  BGRef(const BGRef& rs)                            { copy_assign(rs); }
  BGRef(BGRef&& rs)                                 { move_assign(std::move(rs)); rs.zero(); }
  ~BGRef()                                          { zero(); }

  operator _Tp() const                              { return get(); }

  BGRef& operator =(const _Tp rs)                   { set(rs); return *this; }
  BGRef& operator =(const BGRef& rs)                { copy_assign(rs); return *this; }
  BGRef& operator =(BGRef&& rs)                     { move_assign(std::move(rs)); rs.zero(); return *this; }

  bool operator ==(_Tp rs) const                    { return fRef == rs; }
  bool operator !=(_Tp rs) const                    { return !(*this == rs); }
  bool operator ==(const BGRef& rs) const           { return *this == (_Tp)rs; }
  bool operator !=(const BGRef& rs) const           { return !(*this == rs); }
  bool operator !() const                           { return fRef == NULL || fRef == nil || fRef == Nil; }

  void zero()                                       { fRef = NULL; getter = NULL; setter = NULL; }

private:
  void copy_assign(const BGRef& rs)                 { getter = rs.getter; setter = rs.setter; set(rs.fRef); }
  void move_assign(BGRef&& rs)                      { getter = std::move(rs.getter); setter = std::move(rs.setter); move_set(std::move(rs.fRef)); }

  _Tp& get()                                        { if (getter != NULL) return getter(fRef); return fRef; }
  void set(const _Tp& rs)                           { if (setter != NULL) fRef = setter(fRef, rs); else fRef = rs; }
  void move_set(_Tp&& rs)                           { if (setter != NULL) fRef = std::move(setter(fRef, rs)); else fRef = std::move(rs); }

  _Tp fRef;
  get_block getter;
  set_block setter;
};