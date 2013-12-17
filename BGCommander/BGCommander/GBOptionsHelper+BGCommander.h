#import "GBOptionsHelper.h"

@interface GBOptionsHelper (BGCommander)

-(void)registerOptionsFromDefinitions:(GBOptionDefinition *)definitions count:(NSUInteger)count;

-(NSString*)versionString;
-(NSString*)helpString;
-(NSString*)valuesStringFromSettings:(GBSettings*)settings;

-(NSString*)helpStringWithLeadingSpaces:(int)spaces;

@end
