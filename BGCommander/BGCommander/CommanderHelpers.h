#import "BGCommander.h"
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