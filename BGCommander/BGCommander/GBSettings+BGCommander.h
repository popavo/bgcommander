#import <GBSettings.h>

@interface GBSettings (BGCommander)

+(GBSettings*)commandSettingsWithName:(NSString*)name parent:(GBSettings*)parent;

#pragma mark - Debugging aid

@property (nonatomic, assign) BOOL printSettings;
@property (nonatomic, assign) BOOL printVersion;
@property (nonatomic, assign) BOOL printHelp;

@end

extern const struct BGSettingKeys {
  NSString *printSettings;
  NSString *printVersion;
  NSString *printHelp;
} BGSettingKeys;