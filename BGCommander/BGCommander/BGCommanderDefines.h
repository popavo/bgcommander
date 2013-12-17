#ifndef __BG_COMMANDER_DEFINES_H__
#define __BG_COMMANDER_DEFINES_H__

#define TESTING 0

#ifndef __has_attribute         // Optional of course.
# define __has_attribute(x) 0 // Compatibility with non-clang compilers.
#endif

#define EQ_OPERATOR(__type, __test) \
  bool operator ==(__type rs) const { return __test; } \
  bool operator !=(__type rs) const { return !(*this == rs); }

#if !defined(NO_RETURN)
# if __has_attribute(analyzer_noreturn)
#  define NO_RETURN __attribute__((analyzer_noreturn))
# else
#  define NO_RETURN
# endif
#endif

#if !defined(CHAR_FORMAT_FUNCTION)
# if (__GNUC__*10+__GNUC_MINOR__ >= 42) && (TARGET_OS_MAC || TARGET_OS_EMBEDDED)
#  define CHAR_FORMAT_FUNCTION(F,A) __attribute__((format(printf, F, A)))
# else
#  define CHAR_FORMAT_FUNCTION(F,A)
# endif
#endif

#if !defined(FORCE_INLINE)
# if __has_attribute(always_inline)
#  define FORCE_INLINE __inline__ __attribute__((always_inline))
# else
#  define FORCE_INLINE __inline__
# endif
#endif

#define BGCOMMANDER_STR(x) #x
#define BGCOMMANDER_STRINGIFY(macro) BGCOMMANDER_STR(macro)

#if defined(BGCOMMANDER_VERSION)
# define VERSION_STR BGCOMMANDER_STRINGIFY(BGCOMMANDER_VERSION)
#else
# define VERSION_STR "##VERSION##"
#endif

#if defined(BGCOMMANDER_BUILD)
# define BUILD_STR BGCOMMANDER_STRINGIFY(BGCOMMANDER_BUILD)
#else
# define BUILD_STR "##BUILD##"
#endif

#if defined(BGCOMMANDER_NAME)
# define NAME_STR BGCOMMANDER_STRINGIFY(BGCOMMANDER_NAME)
#else
# define NAME_STR "##LIB##"
#endif

#define VERSION (@ VERSION_STR)
#define BUILD (@ BUILD_STR)
#define NAME (@ NAME_STR)

#endif