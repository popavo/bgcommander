FORCE_INLINE BOOL stringContainsString(NSString* self, NSString* aString) {
  if (!self)
    return NO;

  return [self rangeOfString:aString options:NSLiteralSearch].length > 0;
}

FORCE_INLINE BOOL stringContainsStringLike(NSString* self, NSString* aString) {
  if (!self)
    return NO;

  return [self rangeOfString:aString options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch].length > 0;
}