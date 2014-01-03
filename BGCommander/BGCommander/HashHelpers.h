#import "BGCommander.h"
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
  struct hash<id> {
    size_t operator()(const id& __v) {
      printf("Using id hasher\n");
      return [__v hash];
    }
  };

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

  template<>
  struct hash<bg::OptionDefinitionVector::iterator> {
    size_t operator()(const bg::OptionDefinitionVector::iterator& __v) {
      hash<GBOptionDefinition> hasher;
      return hasher(*__v);
    }
  };

  template <>
  struct hash<bg::StringRef> {
    size_t operator()(const bg::StringRef& __v) const {
      return __v.hash();
    }
  };

  template<>
  struct hash<bg::Command> {
    size_t operator()(const bg::Command& __v) const {
      return __v.hash();
    }
  };

  template<>
  struct hash<bg::CommandVector::const_iterator> {
    size_t operator()(bg::CommandVector::const_iterator __v) {
      hash<bg::Command> hasher;
      return hasher(*__v);
    }
  };
}