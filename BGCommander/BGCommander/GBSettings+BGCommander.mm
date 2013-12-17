#import "GBSettings+BGCommander.h"

@implementation GBSettings (BGCommander)

+(GBSettings*) commandSettingsWithName:(NSString *)name parent:(GBSettings *)parent {
  id result = [self settingsWithName:name parent:parent];
  if (result) {  }
  return result;
}

#pragma mark - Debugging aid

GB_SYNTHESIZE_BOOL(printSettings, setPrintSettings, BGSettingKeys.printSettings)
GB_SYNTHESIZE_BOOL(printVersion, setPrintVersion, BGSettingKeys.printVersion)
GB_SYNTHESIZE_BOOL(printHelp, setPrintHelp, BGSettingKeys.printHelp)

@end

const struct BGSettingKeys BGSettingKeys = {
  .printSettings = @"print-settings",
  .printVersion = @"version",
  .printHelp = @"help",
};