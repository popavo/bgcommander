#import "GBOptionsHelper+BGCommander.h"
#import "GBOptionsHelper.m"

@implementation GBOptionsHelper (BGCommander)

-(void)registerOptionsFromDefinitions:(GBOptionDefinition *)definitions count:(NSUInteger)count {
  for (NSUInteger i = 0; i < count; i++) {
    GBOptionDefinition def = definitions[i];
    [self registerOption:def.shortOption long:def.longOption description:def.description flags:def.flags];
  }
}

+(id) new {
  GBOptionsHelper* helper = [super new];
  if (![helper isKindOfClass:[GBOptionsHelper class]]) return helper;
  helper.applicationName = ^{ return [[NSProcessInfo processInfo] processName]; };
  helper.applicationVersion = ^{ return VERSION; };
  helper.applicationBuild = ^{ return BUILD; };
  return helper;
}

-(NSString*) replacePlaceholdersFromBlock:(GBOptionStringBlock)block {
  if (!block) return @"";

  NSString *string = block();
	string = [string stringByReplacingOccurrencesOfString:@"%APPNAME" withString:self.applicationNameFromBlockOrDefault];
	string = [string stringByReplacingOccurrencesOfString:@"%APPVERSION" withString:self.applicationVersionFromBlockOrNil];
	string = [string stringByReplacingOccurrencesOfString:@"%APPBUILD" withString:self.applicationBuildFromBlockOrNil];
  string = [string stringByReplacingOccurrencesOfString:@"%CMDNAME" withString:@""];

  return string;
}

-(NSString*) versionString {
  NSMutableString *output = [NSMutableString stringWithFormat:@"%@", self.applicationNameFromBlockOrDefault];
	NSString *version = self.applicationVersionFromBlockOrNil;
	NSString *build = self.applicationBuildFromBlockOrNil;
	if (version) [output appendFormat:@": version %@", version];
	if (build) [output appendFormat:@" (build %@)", build];
  return [output copy];
}

-(NSString*) helpString {
  return [self helpStringWithLeadingSpaces:0];
}

-(NSString*)helpStringWithLeadingSpaces:(int)spaces {
  __block NSUInteger maxNameTypeLength = 0;
	__block NSUInteger lastSeparatorIndex = NSNotFound;
	NSMutableArray *rows = [NSMutableArray array];
	[self enumerateOptions:^(OptionDefinition *definition, BOOL *stop) {
		if (![self isHelp:definition]) return;

		// Prepare separator. Remove previous one if there were no values prepared for it.
		if ([self isSeparator:definition]) {
			if (rows.count == lastSeparatorIndex) {
				[rows removeLastObject];
				[rows removeLastObject];
			}
      if (rows.count > 0) {
        [rows addObject:[NSArray array]];
      }
			[rows addObject:[NSArray arrayWithObject:definition.description]];
			lastSeparatorIndex = rows.count;
			return;
		}

		// Prepare option description.
		NSString *shortOption = @"   ";
		NSString *longOption = @"";

    if (definition.shortOption > 0) {
      shortOption = [NSString stringWithFormat:@"-%c%@", definition.shortOption, (definition.longOption && definition.longOption.length > 0) ? @"," : @" "];
    }

    if (definition.longOption && definition.longOption.length > 0) {
      longOption = [NSString stringWithFormat:@"--%@", definition.longOption];
    }
		NSString *description = definition.description;
		NSUInteger requirements = [self requirements:definition];

		// Prepare option type and update longest option+type string size for better alignment later on.
		NSString *type = @"";
		if (requirements == GBValueRequired)
			type = @" <value>";
		else if (requirements == GBValueOptional)
			type = @" [<value>]";
    maxNameTypeLength = MAX(longOption.length + type.length, maxNameTypeLength);
		NSString *nameAndType = [NSString stringWithFormat:@"%@%@", longOption, type];

		// Add option info to rows array.
		NSMutableArray *columns = [NSMutableArray array];
		[columns addObject:shortOption];
		[columns addObject:nameAndType];
		[columns addObject:description];
		[rows addObject:columns];
	}];

  maxNameTypeLength += spaces;

	// Remove last separator if there were no values.
	if (rows.count == lastSeparatorIndex) {
		[rows removeLastObject];
		[rows removeLastObject];
	}

  NSString* rowLead = [NSString stringWithFormat:@"%*s", spaces, ""];

	// Render header.
  NSMutableString* helpString = [NSMutableString new];
  [helpString appendString:[self replacePlaceholdersFromBlock:self.printHelpHeader]];

	// Render all rows aligning long option columns properly.
	[rows enumerateObjectsUsingBlock:^(NSArray *columns, NSUInteger rowIdx, BOOL *stop) {
		NSMutableString *output = [rowLead mutableCopy];
		[columns enumerateObjectsUsingBlock:^(NSString *column, NSUInteger colIdx, BOOL *stop) {
			[output appendFormat:@"%@ ", column];
			if (colIdx == 1) {
				NSUInteger length = column.length;
        while (length < maxNameTypeLength) {
          [output appendString:@" "];
          length++;
        }
			}
		}];
    [helpString appendFormat:@"%@\n", output];
	}];

	// Render footer.
  [helpString appendString:[self replacePlaceholdersFromBlock:self.printHelpFooter]];
  
  return helpString;
}

-(NSString*)valuesStringFromSettings:(GBSettings*)settings {
  NSMutableString* valuesString = [NSMutableString new];

  NSMutableArray *rows = [NSMutableArray array];
	NSMutableArray *lengths = [NSMutableArray array];
	__weak GBOptionsHelper *blockSelf = self;
	__block NSUInteger settingsHierarchyLevels = 0;

	// First add header row. Note that first element is the setting.
	NSMutableArray *headers = [NSMutableArray arrayWithObject:@"Option"];
	[lengths addObject:[NSNumber numberWithUnsignedInteger:[headers.lastObject length]]];
	[settings enumerateSettings:^(GBSettings *settings, BOOL *stop) {
		[headers addObject:settings.name];
		[lengths addObject:[NSNumber numberWithUnsignedInteger:settings.name.length]];
		settingsHierarchyLevels++;
	}];
	[rows addObject:headers];

	// Append all rows for options.
	__block NSUInteger lastSeparatorIndex = 0;
	[self enumerateOptions:^(OptionDefinition *definition, BOOL *stop) {
		if (![blockSelf isPrint:definition]) return;

		// Add separator. Note that we don't care about its length, we'll simply draw it over the whole line if needed.
		if ([blockSelf isSeparator:definition]) {
			if (rows.count == lastSeparatorIndex) {
				[rows removeLastObject];
				[rows removeLastObject];
			}
			NSArray *separators = [NSArray arrayWithObject:definition.description];
			[rows addObject:[NSArray array]];
			[rows addObject:separators];
			lastSeparatorIndex = rows.count;
			return;
		}

		// Prepare values array. Note that the first element is simply the name of the option.
		NSMutableArray *columns = [NSMutableArray array];
		NSString *longOption = definition.longOption;
		GB_UPDATE_MAX_LENGTH(longOption)
		[columns addObject:longOption];

		// Now append value for the option on each settings level and update maximum size.
		[settings enumerateSettings:^(GBSettings *settings, BOOL *stop) {
			NSString *columnData = @"";
			if ([settings isKeyPresentAtThisLevel:longOption]) {
				id value = [settings objectForKey:longOption];
				if ([settings isKeyArray:longOption]) {
					NSMutableString *arrayValue = [NSMutableString string];
					[(NSArray *)value enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
						GBSettings *level = [settings settingsForArrayValue:obj key:longOption];
						if (level != settings) return;
						if (arrayValue.length > 0) [arrayValue appendString:@", "];
						[arrayValue appendString:obj];
					}];
					columnData = arrayValue;
				} else {
					columnData = [value description];
				}
			}
			GB_UPDATE_MAX_LENGTH(columnData)
			[columns addObject:columnData];
		}];

		// Add the row.
		[rows addObject:columns];
	}];

	// Remove last separator if there were no values.
	if (rows.count == lastSeparatorIndex) {
		[rows removeLastObject];
		[rows removeLastObject];
	}

	// Render header.
  [valuesString appendString:[self replacePlaceholdersFromBlock:self.printValuesHeader]];

	// Render all arguments if any.
	if (settings.arguments.count > 0) {
		[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesArgumentsHeader];
		[settings.arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL *stop) {
      [valuesString appendFormat:@"- %@", argument];
			if (settingsHierarchyLevels > 1) {
				GBSettings *level = [settings settingsForArgument:argument];
        [valuesString appendFormat:@" (%@)", level.name];
			}
      [valuesString appendString:@"\n"];
		}];
    [valuesString appendString:@"\n"];
	}

	// Render all rows.
	[self replacePlaceholdersAndPrintStringFromBlock:self.printValuesOptionsHeader];
	[rows enumerateObjectsUsingBlock:^(NSArray *columns, NSUInteger rowIdx, BOOL *stopRow) {
		NSMutableString *output = [NSMutableString string];
		[columns enumerateObjectsUsingBlock:^(NSString *value, NSUInteger colIdx, BOOL *stopCol) {
			NSUInteger columnSize = [[lengths objectAtIndex:colIdx] unsignedIntegerValue];
			NSUInteger valueSize = value.length;
			[output appendString:value];
			while (valueSize <= columnSize) {
				[output appendString:@" "];
				valueSize++;
			}
		}];
    [valuesString appendFormat:@"%@\n", output];
	}];

	// Render footer.
	[valuesString appendString:[self replacePlaceholdersFromBlock:self.printValuesFooter]];

  return [valuesString copy];
}

@end
