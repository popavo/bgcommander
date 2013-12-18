#import "BGCommander.h"

BGCommander commander = BGCommander::sharedCommander();

BGCommander& BGCommander::sharedCommander() {
  static BGCommander _sharedCommander;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Ensures that the shared app command is initialized
    // This probably isn't needed
    BGCommand::sharedAppCommand();
  });
  return _sharedCommander;
}

BGCommander::BGCommander() {
  runResult = INT32_MIN;

  GBOptionsHelper* options = [GBOptionsHelper new];

  options.applicationName = ^{ return [[NSProcessInfo processInfo] processName]; };
  options.applicationVersion = ^{ return VERSION; };
  options.applicationBuild = ^{ return BUILD; };
  options.printValuesHeader = ^{ return @"%APPNAME version %APPVERSION (build %APPBUILD)\n"; };
  options.printValuesArgumentsHeader = ^{ return @"Running with arguments:\n"; };
  options.printValuesOptionsHeader = ^{ return @"Running with options:\n"; };
  options.printValuesFooter = ^{ return @"\nEnd of values print...\n"; };
  options.printHelpHeader = ^{ return @"Usage %APPNAME [OPTIONS] <arguments separated by space>"; };
  options.printHelpFooter = ^{ return @"\nSwitches that don't accept value can use negative form with --no-<name> or --<name>=0 prefix."; };
}

BGCommandVector& BGCommander::commands()                                      { return BGCommand::AppCommand.commands; }
BGCommand& BGCommander::operator [](const BGString& _n)                       { return BGCommand::AppCommand[_n]; }
const BGCommand& BGCommander::operator [](const BGString& _n) const           { return BGCommand::AppCommand[_n]; }
BGCommander::iterator BGCommander::begin()                                    { return BGCommand::AppCommand.begin(); }
BGCommander::iterator BGCommander::end()                                      { return BGCommand::AppCommand.end(); }
BGCommander::const_iterator BGCommander::cbegin() const                       { return BGCommand::AppCommand.cbegin(); }
BGCommander::const_iterator BGCommander::cend() const                         { return BGCommand::AppCommand.cend(); }
bool BGCommander::hasCommand(const BGCommand& rs) const                       { return !!rs && (BGCommand::AppCommand == rs || BGCommand::AppCommand.hasCommand(rs)); }
BGCommander::iterator BGCommander::find(const BGString& name)                 { return BGCommand::AppCommand.find(name); }
BGCommander::const_iterator BGCommander::find(const BGString& name) const     { return BGCommand::AppCommand.find(name); }
BGCommand& BGCommander::command(const BGString& _n, bool addIfMissing)        { return BGCommand::AppCommand == _n ? BGCommand::AppCommand : *BGCommand::AppCommand.command(_n, addIfMissing); }
BGCommander::iterator BGCommander::removeCommand(const BGCommand& _c)         { return BGCommand::AppCommand.removeCommand(_c); }
BGCommand& BGCommander::addCommand(const BGCommand& __c)                      { BGCommand::AppCommand.addCommand(__c); return *find(__c.name); }

BGCommander::add_result BGCommander::addCommand(const BGCommand& c, const BGCommand& parent) {
  if (!c) return {end(), false};

  if (!parent || parent.is_equal(BGCommand::AppCommand)) {
    return BGCommand::AppCommand.addCommand(c);
  }

  iterator i = BGCommand::AppCommand.search(parent.name);
  if (i != end()) {
    return i->addCommand(c);
  }

  return {end(),false};
}

BGCommander::search_depth BGCommander::search(const BGString& name, NSInteger maxDepth)               { NSInteger depth = 0; return BGCommand::AppCommand.search(name, maxDepth, depth); }
BGCommander::const_search_depth BGCommander::search(const BGString& name, NSInteger maxDepth) const   { NSInteger depth = 0; return BGCommand::AppCommand.search(name, maxDepth, depth); }
BGCommander::search_depth BGCommander::search(const BGCommand& cmd, NSInteger maxDepth)               { NSInteger depth = 0; return BGCommand::AppCommand.search(cmd, maxDepth, depth); }
BGCommander::const_search_depth BGCommander::search(const BGCommand& cmd, NSInteger maxDepth) const   { NSInteger depth = 0; return BGCommand::AppCommand.search(cmd, maxDepth, depth); }

BGCommander::iterator BGCommander::command(BGStringVector command_path) {
  BGCommand cmd = BGCommand::AppCommand;
  iterator i = cmd.end();
  for (auto const& name:command_path) {
    i = cmd.find(name);
    if (i == cmd.end()) break;
    cmd = *i;
  }
  return i;
}

void BGCommander::resetAllParentRefs() {
  BGCommand::AppCommand.resetParentRefs();
}

int BGCommander::run() {
  if (runResult > INT32_MIN) return runResult;
  BGStringVector args = [[[NSProcessInfo processInfo] arguments] stringVector];
  args.erase(args.begin());
  BGCommand cmd = BGCommand::AppCommand.parseCommand(args);
  if (!cmd.parse(args)) {
    cmd.printHelp(1);
  }
  args = cmd.settings.arguments.stringVector;
  runResult = cmd.run(args);
  return runResult;
}
