#import "GBOptionsHelper.h"

@interface GBOptionsHelper (BGCommander)

-(void)registerOptionsFromDefinitions:(GBOptionDefinition *)definitions count:(NSUInteger)count;

-(NSString*)helpString;
-(NSString*)helpStringWithLeadingSpaces:(int)spaces;

-(NSString*)versionString;

-(NSString*)valuesStringFromSettings:(GBSettings*)settings;
-(NSString*)valuesStringFromSettings:(GBSettings*)settings includeArguments:(BOOL)includeArgs;


@end