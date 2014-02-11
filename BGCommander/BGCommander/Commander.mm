#import "Commander.h"
#import <utility>

BG_NAMESPACE

Commander& commander = Commander::sharedCommander();

Commander& Commander::sharedCommander() {
  static Commander _sharedCommander;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Ensures that the shared app command is initialized
    // This probably isn't needed
    Command::sharedAppCommand();
  });
  return _sharedCommander;
}

CommandVector& Commander::commands()                                      { return Command::AppCommand.commands; }
Command& Commander::operator [](const StringRef& _n)                         { return Command::AppCommand[_n]; }
const Command& Commander::operator [](const StringRef& _n) const             { return Command::AppCommand[_n]; }
Commander::iterator Commander::begin()                                    { return Command::AppCommand.begin(); }
Commander::iterator Commander::end()                                      { return Command::AppCommand.end(); }
Commander::const_iterator Commander::cbegin() const                       { return Command::AppCommand.cbegin(); }
Commander::const_iterator Commander::cend() const                         { return Command::AppCommand.cend(); }
bool Commander::hasCommand(const Command& rs) const                       { return !!rs && (Command::AppCommand == rs || Command::AppCommand.hasCommand(rs)); }
Commander::iterator Commander::find(const StringRef& name)                   { return Command::AppCommand.find(name); }
Commander::const_iterator Commander::find(const StringRef& name) const       { return Command::AppCommand.find(name); }
Command& Commander::command(const StringRef& _n, bool addIfMissing)          { return Command::AppCommand == _n ? Command::AppCommand : *Command::AppCommand.command(_n, addIfMissing); }
Commander::iterator Commander::removeCommand(const Command& _c)           { return Command::AppCommand.removeCommand(_c); }
Command& Commander::addCommand(const Command& __c)                        { Command::AppCommand.addCommand(__c); return *find(__c.name); }

Commander::add_result Commander::addCommand(const Command& c, const Command& parent) {
  if (!c) return {end(), false};

  if (!parent || parent.is_equal(Command::AppCommand)) {
    return Command::AppCommand.addCommand(c);
  }

  iterator i = Command::AppCommand.search(parent.name);
  if (i != end()) {
    return i->addCommand(c);
  }

  return {end(),false};
}

Commander::search_depth Commander::search(const StringRef& name, NSInteger maxDepth)               { NSInteger depth = 0; return Command::AppCommand.search(name, maxDepth, depth); }
Commander::const_search_depth Commander::search(const StringRef& name, NSInteger maxDepth) const   { NSInteger depth = 0; return Command::AppCommand.search(name, maxDepth, depth); }
Commander::search_depth Commander::search(const Command& cmd, NSInteger maxDepth)               { NSInteger depth = 0; return Command::AppCommand.search(cmd, maxDepth, depth); }
Commander::const_search_depth Commander::search(const Command& cmd, NSInteger maxDepth) const   { NSInteger depth = 0; return Command::AppCommand.search(cmd, maxDepth, depth); }

Commander::iterator Commander::command(StringVector command_path) {
  Command cmd = Command::AppCommand;
  iterator i = cmd.end();
  for (auto const& name:command_path) {
    i = cmd.find(name);
    if (i == cmd.end()) break;
    cmd = *i;
  }
  return i;
}

void Commander::resetAllParentRefs() {
  Command::AppCommand.resetParentRefs();
}

int Commander::run(StringVector& args) {
  Command& cmd = Command::AppCommand.parseCommand(args);
  if (!cmd.parse(args)) {
    cmd.printHelp(1);
  }
  args = cmd.settings.arguments.stringVector;
  int runResult = cmd.run(args);
  return runResult;
}

BG_NAMESPACE_END