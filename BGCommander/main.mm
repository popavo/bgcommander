//
//  main.m
//  Commander
//
//  Created by Brian K Garrett on 12/2/13.
//  Copyright (c) 2013 Brian K Garrett. All rights reserved.
//

#import <Foundation/Foundation.h>

int list_main(StringVector args, GBSettings* options, Command& command) {
  std::cout << __PRETTY_FUNCTION__ << std::endl << args;
  return 0;
}

int main(int argc, const char* argv[]) {

  @autoreleasepool {
    CommanderAutoRunner autorunner;

    OptionDefinitionVector addOpts = {{'n', @"dry-run", @"Only show what would happen", GBValueNone},
                                      {'v', @"verbose", @"Be verbose", GBValueNone},
                                      {'f', @"force", @"Allow adding otherwise ignored files", GBValueNone},
                                      {'i', @"interactive", @"Add files in \"Interactive mode\"", GBValueNone}};

    Command addCmd("add", "Add files to the list", addOpts);
    commander.addCommand(addCmd);

    Command listCmd("list");

    listCmd.setRunBlock(^int(StringVector args, GBSettings* options, Command& command) {
      std::cout << args << std::endl;
      return 0;
    });

    listCmd.setRunFunction(list_main);

    Command::add_result addList = Command::sharedAppCommand().addCommand(listCmd);
    if (addList.second) {
      Command allCmd("all");
      Command::add_result addAll = addList.first->addCommand(allCmd);
      Command listall("list-all");
      addAll.first->addCommand(listall);
    }

    Commander::add_result result = Command::sharedAppCommand().addCommand("swap");
    result.first->setRunBlock(^int(StringVector args, GBSettings* settings, Command& command) { return 0; });

    printf("\nCommander commands:\n");
    for (auto& command : Command::sharedAppCommand().commands) {
      command.inspect(3).append("\n").print();
    }
  }

  return 0;
}
