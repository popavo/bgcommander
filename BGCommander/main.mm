//
//  main.m
//  BGCommander
//
//  Created by Brian K Garrett on 12/2/13.
//  Copyright (c) 2013 Brian K Garrett. All rights reserved.
//

#import <Foundation/Foundation.h>

int list_main(BGStringVector args, GBSettings* options, BGCommand& command) {
  std::cout << __PRETTY_FUNCTION__ << std::endl << args;
  return 0;
}

int main(int argc, const char * argv[]) {

  @autoreleasepool {
    CommanderAutoRunner autorunner;

    BGOptionDefinitionVector addOpts = {
      { 'n', @"dry-run", @"Only show what would happen", GBValueNone },
      { 'v', @"verbose", @"Be verbose", GBValueNone },
      { 'f', @"force", @"Allow adding otherwise ignored files", GBValueNone },
      { 'i', @"interactive", @"Add files in \"Interactive mode\"", GBValueNone }
    };

    BGCommand addCmd("add", "Add files to the list", addOpts);
    commander.addCommand(addCmd);

    BGCommand listCmd("list");

    listCmd.setRunBlock(^int(BGStringVector args, GBSettings *options, BGCommand &command) {
      std::cout << args << std::endl;
      return 0;
    });

    listCmd.setRunFunction(list_main);

    BGCommand::add_result addList = commander.addCommand(listCmd);
    if (addList.second) {
      BGCommand allCmd("all");
      BGCommand::add_result addAll = addList.first->addCommand(allCmd);
      BGCommand listall("list-all");
      addAll.first->addCommand(listall);
    }

    BGCommander::add_result result = commander.addCommand("swap");
    result.first->setRunBlock(^int(BGStringVector args, GBSettings *settings, BGCommand& command) {
      return 0;
    });

    printf("\nCommander commands:\n");
    for (auto & command:BGCommand::sharedAppCommand().commands) {
      command.inspect(3).append("\n").print();
    }
  }

  return 0;
}

