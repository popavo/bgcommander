#import "BGCommanderDefines.h"
#import "GBSettings+BGCommander.h"
#import "GBOptionsHelper+BGCommander.h"
#import <sysexits.h>

#define VA_STR(__format, __formatArg, __name) \
  va_list __ap; \
  va_start(__ap, __format); \
  NSString* __name = [[NSString alloc] initWithFormat:__formatArg arguments:__ap]; \
  va_end(__ap); \

FORCE_INLINE void die(FILE *output, int val, NSString* format, ...) NS_FORMAT_FUNCTION(3, 4) NO_RETURN {
  VA_STR(format, format, print);
  fprintf(output, "%s\n", print.UTF8String);
  exit(val);
}

FORCE_INLINE void die(int val, NSString* format, ...) NS_FORMAT_FUNCTION(2, 3) NO_RETURN {
  VA_STR(format, format, print);
  die(stderr, val, @"%@", print);
}

FORCE_INLINE void die(NSString* format, ...) NS_FORMAT_FUNCTION(1, 2) NO_RETURN {
  VA_STR(format, format, print);
  die(EX_SOFTWARE, @"%@", print);
}

#import <memory>

template <class T>
inline void hash_combine(std::size_t& seed, T const& v) {
  std::hash<T> hasher;
  seed ^= hasher(v) + 0x9e3779b9 + (seed<<6) + (seed>>2);
}

template <class It>
inline std::size_t hash_range(It first, It last) {
  std::size_t seed = 0;

  for(; first != last; ++first) {
    hash_combine(seed, *first);
  }

  return seed;
}

template <class It>
inline void hash_range(std::size_t& seed, It first, It last) {
  for(; first != last; ++first) {
    hash_combine(seed, *first);
  }
}

#define OBJC_STD_HASH(__type) \
template <> \
struct std::hash<__type> { \
  std::size_t operator()(__type __v) { \
    return [__v hash]; \
  } \
}

OBJC_STD_HASH(GBOptionsHelper*);
OBJC_STD_HASH(GBSettings*);
OBJC_STD_HASH(GBCommandLineParser*);
OBJC_STD_HASH(NSString*);

namespace std {
  template<>
  struct hash<GBOptionDefinition> {
    size_t operator()(const GBOptionDefinition& __v) {
      size_t seed = 0;
      hash_combine(seed, __v.shortOption);
      hash_combine(seed, __v.longOption);
      hash_combine(seed, __v.description);
      hash_combine(seed, __v.flags);
      return seed;
    }
  };
}