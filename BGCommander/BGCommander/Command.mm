#import "Command.h"
#import <utility>

@interface GBSettings (Private)
@property(nonatomic, readwrite, copy) NSString* name;
@property(nonatomic, readwrite, strong) GBSettings* parent;
@end

BG_NAMESPACE

Command& Command::AppCommand = Command::sharedAppCommand();

Command& Command::sharedAppCommand() {
  static Command _sharedAppCommand([[NSProcessInfo processInfo] processName]);
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedAppCommand._isAppCommand = true;
    _sharedAppCommand.addCommand("help", "Display global or [command] help documentation");
    _sharedAppCommand.addGlobalOption(0, @"version", @"Display version information", GBValueNone | GBOptionNoPrint);
    _sharedAppCommand.addGlobalOption('h', @"help", @"Display help documentation", GBValueNone | GBOptionNoPrint);
    _sharedAppCommand.setRunBlock(^int(StringVector args, GBSettings* options, Command& command) { return 0; });
  });
  return _sharedAppCommand;
}

void Command::_initIvars() {
  name = @"";
  description = @"";
  syntax = {};
  tag = 0;
  commands = {};
  optionDefinitions = {};
  globalOptionDefinitions = {};
  optionsHelper = nil;
  settings = nil;
  parser = nil;
  runBlock = NULL;
  runFunction = NULL;
  _isAppCommand = false;
  _identifier = 0;
  _needsOptionsReset = true;
  parent = nullptr;
}

void Command::_initNameDeps() {
  if (name.valid()) {
    if (!settings)
      settings = [GBSettings commandSettingsWithName:name parent:nil];
    settings.name = name;
  }
}

void Command::_commonInit(const StringRef& _s) {
  nameWrapper = false;
  _initIvars();
  name = _s;
  _initNameDeps();
  _identifier = arc4random_uniform(UINT_MAX);
  optionsHelper = [GBOptionsHelper new];
  parser = [GBCommandLineParser new];

  optionsHelper.applicationVersion = ^{ return VERSION; };
  optionsHelper.applicationBuild = ^{ return BUILD; };
}

void Command::_finishInit() {}

void Command::_copyAssign(const Command& rs) {
  if (rs.nameWrapper) {
    name = rs.name;
    nameWrapper = rs.nameWrapper;
    return;
  }
  _commonInit(rs.name);
  description = rs.description;
  syntax = rs.syntax;
  tag = rs.tag;
  commands = rs.commands;
  optionDefinitions = rs.optionDefinitions;
  globalOptionDefinitions = rs.globalOptionDefinitions;
  optionsHelper = rs.optionsHelper;
  settings = rs.settings;
  parser = rs.parser;
  runBlock = rs.runBlock;
  runFunction = rs.runFunction;
  nameWrapper = rs.nameWrapper;
  _isAppCommand = rs._isAppCommand;
  _identifier = rs._identifier;
  _needsOptionsReset = rs._needsOptionsReset;
  parent = rs.parent;
  resetParentRefs();
}

void Command::_moveAssign(Command&& rs) {
  if (rs.nameWrapper) {
    name = std::move(rs.name);
    nameWrapper = std::move(rs.nameWrapper);
    rs.clear();
    return;
  }
  _initIvars();
  name = std::move(rs.name);
  description = std::move(rs.description);
  syntax = std::move(rs.syntax);
  tag = std::move(rs.tag);
  commands = std::move(rs.commands);
  optionDefinitions = std::move(rs.optionDefinitions);
  globalOptionDefinitions = std::move(rs.globalOptionDefinitions);
  optionsHelper = std::move(rs.optionsHelper);
  settings = std::move(rs.settings);
  parser = std::move(rs.parser);
  runBlock = std::move(rs.runBlock);
  runFunction = std::move(rs.runFunction);
  nameWrapper = std::move(rs.nameWrapper);
  _isAppCommand = std::move(rs._isAppCommand);
  _identifier = std::move(rs._identifier);
  _needsOptionsReset = std::move(rs._needsOptionsReset);
  parent = std::move(rs.parent);
  rs.clear();
  resetParentRefs();
}

Command::Command(Command&& rs) { _moveAssign(std::move(rs)); }

Command::Command(const Command& rs) {
  _copyAssign(rs);
  _finishInit();
}

Command::Command(const StringRef& _s, const StringRef& _d, const OptionDefinitionVector& _o) {
  _commonInit(_s);
  description = _d;
  optionDefinitions = _o;
  _finishInit();
}

Command& Command::operator=(const Command& rs) {
  _copyAssign(rs);
  _finishInit();
  return *this;
}

Command& Command::operator=(Command&& rs) {
  _moveAssign(std::move(rs));
  return *this;
}

bool Command::operator!() const { return !name; }
Command::operator bool() const { return valid(); }
bool Command::valid() const { return !!*this; }
bool Command::is_equal(const Command& rs) const {
  if (!rs)
    return false;
  if (nameWrapper || rs.nameWrapper) {
    return name.is_equal(rs.name);
  }
  return (this == &rs) || (_identifier == rs._identifier) || name.is_equal(rs.name);
}

bool Command::isAppCommand() const { return _isAppCommand; }

NSUInteger Command::identifier() const { return _identifier; }

std::size_t Command::hash() const {
  std::size_t seed = 0;

  hash_combine(seed, name);
  if (nameWrapper)
    return seed;

  hash_combine(seed, _identifier);
  hash_combine(seed, tag);
  hash_combine(seed, description);
  hash_combine(seed, optionsHelper);
  hash_combine(seed, settings);
  hash_combine(seed, parser);

  hash_range(seed, syntax.cbegin(), syntax.cend());
  hash_range(seed, optionDefinitions.cbegin(), optionDefinitions.cend());
  hash_range(seed, cbegin(), cend());

  return seed;
}

void Command::resetParentRefs() {
  if (!hasChildren())
    return;
  for (iterator i = begin(); i != end(); i++) {
    i->setParent(*this);
    i->resetParentRefs();
  }
}

int Command::generationDepth() const { return (_isAppCommand || (parent == nullptr)) ? 0 : parent->generationDepth() + 1; }
void Command::setParent(Command& p) { parent = &p; }
bool Command::hasChildren() const { return count() != 0; }

Command::iterator Command::begin() { return commands.begin(); }
Command::iterator Command::end() { return commands.end(); }
Command::const_iterator Command::begin() const { return commands.begin(); }
Command::const_iterator Command::end() const { return commands.end(); }
Command::const_iterator Command::cbegin() const { return commands.cbegin(); }
Command::const_iterator Command::cend() const { return commands.cend(); }

Command& Command::operator[](const StringRef& _n) { return *command(_n, true); }
const Command& Command::operator[](const StringRef& _n) const { return *find(_n); }
bool Command::hasCommand(const StringRef& name) const { return find(name) != cend(); }
bool Command::hasCommand(const Command& rs) const { return find(rs) != cend(); }
Command::iterator Command::find(const Command& cmd) { return std::find(begin(), end(), cmd); }
Command::const_iterator Command::find(const Command& cmd) const { return std::find(cbegin(), cend(), cmd); }
Command::iterator Command::find(const StringRef& name) { return std::find(begin(), end(), name); }
Command::const_iterator Command::find(const StringRef& name) const { return std::find(cbegin(), cend(), name); }

Command::iterator Command::search(const StringRef& name) {
  iterator i = find(name);
  if (i != end())
    return i;
  for (iterator j = begin(); j != end(); j++) {
    i = j->search(name);
    if (i != j->end())
      break;
  }
  return i;
}

Command::const_iterator Command::search(const StringRef& name) const {
  const_iterator i = find(name);
  if (i != end())
    return i;
  for (const_iterator j = begin(); j != end(); j++) {
    i = j->search(name);
    if (i != j->end())
      break;
  }
  return i;
}

#define search_imp(__c, __cmd) \
  if (current < 0) \
    current = 0; \
  if (maxDepth > 0 && current > maxDepth) \
    return {end(), current}; \
  \
  __c ## iterator i = find(name); \
  if (i != end()) {  \
    return {i, ++current}; \
  } \
  \
  for (__c ## iterator j = begin(); j != end(); j++) { \
    __c ## search_depth d = j->search(name, maxDepth, current); \
    if (d.first != j->end()) { \
      d.second++; \
      return d; \
    } \
  } \
  \
  return {end(), current}; \

Command::search_depth Command::search(const StringRef& name, NSInteger maxDepth, NSInteger& current) { search_imp(, name); }
Command::const_search_depth Command::search(const StringRef& name, NSInteger maxDepth, NSInteger& current) const { search_imp(const_, name); }
Command::search_depth Command::search(const Command& cmd, NSInteger maxDepth, NSInteger& current) { search_imp(, cmd); }
Command::const_search_depth Command::search(const Command& cmd, NSInteger maxDepth, NSInteger& current) const { search_imp(const_, cmd); }

Command::iterator Command::command(const StringRef& _n, bool addIfMissing) {
  if (!_n)
    return end();
  if (!hasCommand(_n) && addIfMissing) {
    Command cmd(_n);
    addCommand(cmd);
  }
  return find(_n);
}

Command::add_result Command::addCommand(const Command& c) {
  if (!c.name) {
    printf("Invalid command param\n");
    return {end(), false};
  }

  bool added = false;

  iterator i = end();
  if (!hasCommand(c)) {
    i = commands.insert(cend(), c);
    if (i != end()) {
      i->setParent(*this);
      added = true;
    }
  }

  return {i, added};
}

Command::add_result Command::addCommand(Command&& c) {
  if (!c.name) {
    printf("Invalid command param\n");
    return {end(), false};
  }

  bool added = false;

  iterator i = end();
  if (!hasCommand(c)) {
    i = commands.insert(cend(), std::move(c));
    if (i != end()) {
      i->setParent(*this);
      added = true;
    }
  }

  return {i, added};
}

Command::iterator Command::removeCommand(const Command& _c) { return commands.erase(find(_c.name)); }
Command::iterator Command::addCommands(CommandVector& _c) { return commands.insert(cend(), _c.begin(), _c.end()); }
Command::size_type Command::count() const { return commands.size(); }

void Command::setOptions(const OptionDefinitionVector& rs) {
  optionDefinitions = rs;
  _needsOptionsReset = true;
}
void Command::addOption(const GBOptionDefinition& rs) {
  optionDefinitions.push_back(rs);
  _needsOptionsReset = true;
}
void Command::addOption(GBOptionDefinition&& rs) {
  optionDefinitions.push_back(std::move(rs));
  _needsOptionsReset = true;
}
void Command::removeOption(const GBOptionDefinition& rs) {
  optionDefinitions.remove(rs);
  _needsOptionsReset = true;
}
void Command::removeOption(OptionDefinitionVector::size_type __n) {
  optionDefinitions.remove(__n);
  _needsOptionsReset = true;
}
GBOptionDefinition& Command::optionAt(OptionDefinitionVector::size_type __n) { return optionDefinitions[__n]; }
const GBOptionDefinition& Command::optionAt(OptionDefinitionVector::size_type __n) const { return optionDefinitions[__n]; }

void Command::setGlobalOptions(const OptionDefinitionVector& rs) {
  globalOptionDefinitions = rs;
  _needsOptionsReset = true;
}
void Command::addGlobalOption(const GBOptionDefinition& rs) {
  globalOptionDefinitions.push_back(rs);
  _needsOptionsReset = true;
}
void Command::addGlobalOption(GBOptionDefinition&& rs) {
  globalOptionDefinitions.push_back(std::move(rs));
  _needsOptionsReset = true;
}
void Command::removeGlobalOption(const GBOptionDefinition& rs) {
  globalOptionDefinitions.remove(rs);
  _needsOptionsReset = true;
}
void Command::removeGlobalOption(OptionDefinitionVector::size_type __n) {
  globalOptionDefinitions.remove(__n);
  _needsOptionsReset = true;
}
GBOptionDefinition& Command::globalOptionAt(OptionDefinitionVector::size_type __n) { return globalOptionDefinitions[__n]; }
const GBOptionDefinition& Command::globalOptionAt(OptionDefinitionVector::size_type __n) const { return globalOptionDefinitions[__n]; }

void Command::setSyntaxes(const StringVector& rs) { syntax = rs; }
void Command::addSyntax(const StringRef& rs) { syntax.push_back(rs); }
void Command::removeSyntax(const StringRef& rs) { syntax.erase(std::remove(syntax.begin(), syntax.end(), rs), syntax.end()); }
void Command::removeSyntax(StringVector::size_type __n) {
  if (__n >= syntax.size())
    return;
  removeSyntax(syntax.at(__n));
}
StringRef& Command::syntaxAt(StringVector::size_type __n) { return syntax[__n]; }
const StringRef& Command::syntaxAt(StringVector::size_type __n) const { return syntax[__n]; }

StringRef Command::commandString() { return (_isAppCommand || (parent == nullptr)) ? name : parent->commandString() + " " + this->name; }

void Command::setName(const StringRef& rs) {
  if (rs.valid())
    name = rs;
  _initNameDeps();
}
StringRef Command::getName() const { return name; }
void Command::setDescription(CommandStringBlock descriptionBlock) {
  if (descriptionBlock != NULL)
    description = descriptionBlock(*this);
}
StringRef Command::getDescription() const { return description; }
void Command::setRunBlock(CommandRunBlock __r) {
  runBlock = __r;
  if (runBlock != NULL) {
    setRunFunction(NULL);
  }
}
void Command::setRunFunction(CommandRunFunction __r) {
  runFunction = __r;
  if (runFunction != NULL) {
    setRunBlock(NULL);
  }
}

int Command::run(StringVector& args) {
  if (settings.printHelp) {
    printHelp();
  }

  if (settings.printVersion) {
    printVersion();
  }

  if (runBlock != NULL)
    return runBlock(args, settings, *this);
  if (runFunction != NULL)
    return runFunction(args, settings, *this);
  return -1;
}

void Command::registerDefinitions() {
  if (!_needsOptionsReset)
    return;
  _needsOptionsReset = false;

  if (!settings)
    settings = [GBSettings commandSettingsWithName:name parent:nil];
  optionsHelper = [GBOptionsHelper new];
  parser = [GBCommandLineParser new];

  for (auto const& def : optionDefinitions) {
    [optionsHelper registerOption:def.shortOption long:def.longOption description:def.description flags:def.flags];
  }


  OptionDefinitionVector globalOpts = globalOptions();
  if (globalOpts.size()) {
    [optionsHelper registerOption:0 long:nil description:@"Global Options" flags:GBOptionSeparator];
    for (auto const& gdef : globalOpts) {
      [optionsHelper registerOption:gdef.shortOption long:gdef.longOption description:gdef.description flags:gdef.flags];
    }
  }


  [optionsHelper registerOptionsToCommandLineParser:parser];
}

OptionDefinitionVector Command::globalOptions() {
  OptionDefinitionVector _opts;
  if (!(_isAppCommand || (parent == nullptr))) {
    _opts = parent->globalOptions();
  }

  for (auto const& def : globalOptionDefinitions) {
    _opts.push_back(def);
  }

  return _opts;
}

void Command::setSettingsParent(GBSettings* __p) { settings.parent = __p; }

void Command::setDefaultSettingsValueForKey(const StringRef& _n, id _v) { [settings setObject:_v forKey:_n]; }

void Command::registerArrayForKey(const StringRef& _n) { [settings registerArrayForKey:_n]; }

bool Command::parse(StringVector& args) {
  __block bool valid = true;
  GBCommandLineParseBlock parseBlock = ^(GBParseFlags flags, NSString* option, id value, BOOL* stop) {
    switch (flags) {
      case GBParseFlagUnknownOption:
      case GBParseFlagMissingValue:
        valid = false;
        break;
      case GBParseFlagArgument:
        [settings addArgument:value];
        break;
      case GBParseFlagOption:
        [settings setObject:value forKey:option];
        break;
    }
  };

  return valid && parse(args, parseBlock);
}

bool Command::parse(StringVector& args, GBCommandLineParseBlock parse_block) {
  registerDefinitions();
  return [parser parseOptionsWithArguments:[NSArray stringsFromStringVector:&args] commandLine:name block:parse_block];
}

Command& Command::parseCommand(StringVector& args) {
  if (args.empty()) {
    return *this;
  }

  StringRef cmdString = args.front();

  if (cmdString == "help" || cmdString == "-h" || cmdString == "--help") {
    args.erase(args.begin());
    parseCommand(args).printHelp();
  }

  iterator cmd = find(cmdString);
  if (cmd == end()) {
    return *this;
  }

  args.erase(args.begin());

  return cmd->parseCommand(args);
}

StringRef Command::helpString() {
  registerDefinitions();

  int spacing = 4;
  StringRef help;

  help.setPostAppend(@"\n");

  // Command name
  help.addNewline();
  help += @"NAME:";
  help.appendFormat(@"%*s%@", spacing, "", name.fString);

  // Command synopsis
  if (!isAppCommand()) {
    if (syntax.size()) {
      help.addNewline();
      help += @"SYNOPSIS:";
      for (auto const& syn : syntax) {
        help.appendFormat(@"%*s%@", spacing, "", syn.fString);
      }
    }
  }

  // Command description
  if (description.valid()) {
    help.addNewline();
    help += @"DESCRIPTION:";
    help.appendFormat(@"%*s%@", spacing, "", description.fString);
  }

  // List of sub-commands
  //      command1        command1 description
  //      command2        command2 description
  if (commands.size()) {
    size_t longest = 0;
    help.addNewline();
    help += @"COMMANDS:";

    for (const_iterator i = cbegin(); i != cend(); i++) {
      const Command& command = *i;
      size_t length = command.name.size();
      longest = MAX(longest, length);
    }

    for (auto const& command : commands) {
      StringRef subcommand;
      subcommand.appendFormat(@"%*s%@", spacing, "", command.name.fString);
      size_t diff = longest - command.name.size() + spacing;
      subcommand.appendFormat(@"%*s", (int)diff, "");
      subcommand += command.description;
      help += subcommand;
    }
  }

  // List of options
  NSString* optionsHelp = [optionsHelper helpStringWithLeadingSpaces:spacing];
  if (optionsHelp && optionsHelp.length > 0) {
    help.addNewline();
    help += @"OPTIONS:";
    help += optionsHelp;
  }

  // Footer

  return help;
}

void Command::printHelp(int exitVal) {
  StringRef help = helpString();
  help.print();
  exit(exitVal);
}

void Command::printVersion(int exitVal) {
  if (!optionsHelper)
    printHelp(0);
  [optionsHelper printVersion];
  exit(exitVal);
}

void Command::printSettings(int exitVal) {
  if (!optionsHelper || !settings)
    printHelp(-1);
  StringRef values([optionsHelper valuesStringFromSettings:settings]);
  values.print();
  if (exitVal > INT32_MIN)
    exit(exitVal);
}

// TODO: clear()
void Command::clear() {
  if (nameWrapper) {
    name.zero();
    nameWrapper = 0;
    return;
  }
  nameWrapper = 0;
  _isAppCommand = 0;
  _identifier = 0;
  _needsOptionsReset = 0;
  parent = nullptr;
  name.zero();
  commands.clear();
  optionDefinitions.clear();
  globalOptionDefinitions.clear();
  optionsHelper = nil;
  settings = nil;
  parser = nil;
  tag = 0;
  description.zero();
  syntax.clear();
  runBlock = NULL;
}

StringRef Command::inspect(int leadingSpaces) const {
  StringRef info;
  int gen = generationDepth();
  int prespace = leadingSpaces * (gen - 1);

  info.setPreAppend([NSString stringWithFormat:@"%*s", MAX(prespace, 0), ""]);
  info.setPostAppend(@"\n");

  info.append(name);

  if (identifier()) {
    info.appendFormat(@"Identifier: %lu", identifier());
  }

  if (tag) {
    info.appendFormat(@"Tag: %lu", tag);
  }

  if (gen) {
    info.appendFormat(@"Generation: %d", gen);
  }

  if (count()) {
    info.appendFormat(@"Sub-Commands (%lu):", count());
    if (_isAppCommand) {
      info.addNewline();
    }
    for (auto const& command : commands) {
      info.appendFormatOnly(@"%@", command.inspect(leadingSpaces).fString);
      if (command != commands.back()) {
        info.addNewline();
      }
    }
  }

  return info;
}

BG_NAMESPACE_END
