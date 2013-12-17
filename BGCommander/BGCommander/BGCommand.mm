#import "BGCommand.h"
#import <utility>
#import "GBSettings+BGCommander.h"

BGCommand& BGCommand::AppCommand = BGCommand::sharedAppCommand();

BGCommand& BGCommand::sharedAppCommand() {
  static BGCommand _sharedAppCommand([[NSProcessInfo processInfo] processName]);
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedAppCommand.optionDefinitions = {
      { 'h', @"help", @"Display help documentation", GBValueNone|GBOptionNoPrint },
      { 'V', @"version", @"Display version information", GBValueNone|GBOptionNoPrint }
    };

    _sharedAppCommand.setRunBlock(^int(std::vector<BGString> args, GBSettings *options, BGCommand &command) {
      if (args.empty() || options.printHelp) {
        command.printHelp();
      }
      if (options.printVersion) {
        [command.optionsHelper printVersion];
      }
      return 0;
    });

    _sharedAppCommand.addCommand({"help", "Display global or [command] help documentation"});
  });
  return _sharedAppCommand;
}

void BGCommand::_initIvars() {
  name = @"";
  description = @"";
  syntax = @"";
  tag = 0;
  commands = {};
  optionDefinitions = {};
  optionsHelper = nil;
  settings = nil;
  parser = nil;
  runBlock = NULL;
  runFunction = NULL;
  nameWrapper = false;
  _isAppCommand = false;
  _identifier = 0;
  _needsOptionsReset = true;
  parent = nullptr;
}

void BGCommand::_initNameDeps() {
  if (name.valid()) {
    _isAppCommand = name.is_equal([[NSProcessInfo processInfo] processName]);
    settings = [GBSettings commandSettingsWithName:name parent:nil];
  }
}

void BGCommand::_commonInit(const BGString& _s) {
  _initIvars();
  name = _s;
  _initNameDeps();
  _identifier = arc4random_uniform(UINT_MAX);
  optionsHelper = [GBOptionsHelper new];
  parser = [GBCommandLineParser new];

  addOption({'h', @"help", @"Display help documentation", GBValueNone|GBOptionNoPrint});
}

void BGCommand::_copyAssign(const BGCommand& rs) {
  _commonInit(rs.name);
  description        = rs.description;
  syntax             = rs.syntax;
  tag                = rs.tag;
  commands           = rs.commands;
  optionDefinitions  = rs.optionDefinitions;
  optionsHelper      = rs.optionsHelper;
  settings           = rs.settings;
  parser             = rs.parser;
  runBlock           = rs.runBlock;
  runFunction        = rs.runFunction;
  nameWrapper        = rs.nameWrapper;
  _isAppCommand      = rs._isAppCommand;
  _identifier        = rs._identifier;
  _needsOptionsReset = rs._needsOptionsReset;
  parent             = rs.parent;
  resetParentRefs();
}

void BGCommand::_moveAssign(BGCommand&& rs) {
  _initIvars();
  name               = std::move(rs.name);
  description        = std::move(rs.description);
  syntax             = std::move(rs.syntax);
  tag                = std::move(rs.tag);
  commands           = std::move(rs.commands);
  optionDefinitions  = std::move(rs.optionDefinitions);
  optionsHelper      = std::move(rs.optionsHelper);
  settings           = std::move(rs.settings);
  parser             = std::move(rs.parser);
  runBlock           = std::move(rs.runBlock);
  runFunction        = std::move(rs.runFunction);
  nameWrapper        = std::move(rs.nameWrapper);
  _isAppCommand      = std::move(rs._isAppCommand);
  _identifier        = std::move(rs._identifier);
  _needsOptionsReset = std::move(rs._needsOptionsReset);
  parent             = std::move(rs.parent);
  rs.clear();
  resetParentRefs();
}

BGCommand::BGCommand(BGCommand&& rs) {
  _moveAssign(std::move(rs));
}

BGCommand::BGCommand(const BGCommand& rs) { _copyAssign(rs); }

BGCommand::BGCommand(const BGString& _s, const BGString& _d, const BGOptionDefinitionVector& _o) {
  _commonInit(_s);
  description = _d;
  optionDefinitions = _o;
}

BGCommand::BGCommand(const_char _s, const BGString& _d, const BGOptionDefinitionVector& _o) {
  _commonInit(_s);
  description = _d;
  optionDefinitions = _o;
}

BGCommand::BGCommand(NSString* _s, const BGString& _d, const BGOptionDefinitionVector& _o) {
  _commonInit(_s);
  description = _d;
  optionDefinitions = _o;
}

BGCommand& BGCommand::operator=(const BGCommand &rs) {
  _copyAssign(rs);
  return *this;
}

BGCommand& BGCommand::operator =(BGCommand&& rs) {
  _moveAssign(std::move(rs));
  return *this;
}

bool BGCommand::operator !() const { return !name; }
bool BGCommand::valid() const { return !!*this; }
bool BGCommand::is_equal(const BGCommand& rs) const {
  if (!rs) return false;
  if (nameWrapper || rs.nameWrapper) {
    return name.is_equal(rs.name);
  }
  return (this == &rs) || (_identifier == rs._identifier);
}

bool BGCommand::isAppCommand() const { return _isAppCommand; }

NSUInteger BGCommand::identifier() const { return _identifier; }

std::size_t BGCommand::hash() const {
  std::size_t seed = 0;

  hash_combine(seed, name);
  hash_combine(seed, _identifier);
  hash_combine(seed, tag);
  hash_combine(seed, description);
  hash_combine(seed, syntax);
  hash_combine(seed, optionsHelper);
  hash_combine(seed, settings);
  hash_combine(seed, parser);

  hash_range(seed, optionDefinitions.cbegin(), optionDefinitions.cend());
  hash_range(seed, cbegin(), cend());

  return seed;
}

int BGCommand::generationDepth() const                                    { return (_isAppCommand || (parent == nullptr)) ? 0 : parent->generationDepth() + 1; }
void BGCommand::setParent(BGCommand& p)                                   {  parent = &p; }
bool BGCommand::hasChildren() const                                       { return count() != 0; }

BGCommand::iterator BGCommand::begin()                                    { return commands.begin(); }
BGCommand::iterator BGCommand::end()                                      { return commands.end(); }
BGCommand::const_iterator BGCommand::cbegin() const                       { return commands.cbegin(); }
BGCommand::const_iterator BGCommand::cend() const                         { return commands.cend(); }

void BGCommand::resetParentRefs() {
  if (!hasChildren()) return;
  for (iterator i = begin(); i != end(); i++) {
    i->setParent(*this);
    i->resetParentRefs();
  }
}

BGCommand& BGCommand::operator [](const BGString& _n)                     { return *command(_n, true); }
const BGCommand& BGCommand::operator[](const BGString& _n) const          { return *find(_n); }
bool BGCommand::hasCommand(const BGString& name) const                    { return find(name) != cend(); }
bool BGCommand::hasCommand(const BGCommand& rs) const                     { return find(rs) != cend(); }
BGCommand::iterator BGCommand::find(const BGCommand& cmd)                 { return std::find(commands.begin(), commands.end(), cmd); }
BGCommand::const_iterator BGCommand::find(const BGCommand& cmd) const     { return std::find(commands.cbegin(), commands.cend(), cmd); }
BGCommand::iterator BGCommand::find(const BGString& name)                 { BGCommand cmd = namedWrapper(name); return find(cmd); }
BGCommand::const_iterator BGCommand::find(const BGString& name) const     { BGCommand cmd = namedWrapper(name); return find(cmd); }

BGCommand::iterator BGCommand::search(const BGString& name) {
  iterator i = find(name);
  if (i != end()) return i;
  for (iterator j = begin(); j != end(); j++) {
    i = j->search(name);
    if (i != j->end()) break;
  }
  return i;
}

BGCommand::const_iterator BGCommand::search(const BGString& name) const {
  const_iterator i = find(name);
  if (i != cend()) return i;
  for (const_iterator j = cbegin(); j != cend(); j++) {
    i = j->search(name);
    if (i != j->cend()) break;
  }
  return i;
}

BGCommand::search_depth BGCommand::search(const BGString& name, NSInteger maxDepth, NSInteger& current) { BGCommand cmd = namedWrapper(name); return search(cmd, maxDepth, current); }
BGCommand::const_search_depth BGCommand::search(const BGString& name, NSInteger maxDepth, NSInteger& current) const { BGCommand cmd = namedWrapper(name); return search(cmd, maxDepth, current); }

BGCommand::search_depth BGCommand::search(const BGCommand& cmd, NSInteger maxDepth, NSInteger& current) {
  if (current < 0) current = 0;
  if (maxDepth > 0 && current > maxDepth) return {end(),current};

  iterator i = find(cmd);
  if (i != end()) {
    // Found the command in this.commands vector
    return {i, ++current};
  }

  for (iterator j = begin(); j != end(); j++) {
    search_depth d = j->search(cmd, maxDepth, current);
    if (d.first != j->end()) {
      d.second++;
      return d;
    }
  }

  return {end(),current};
}

BGCommand::const_search_depth BGCommand::search(const BGCommand& cmd, NSInteger maxDepth, NSInteger& current) const {
  if (current < 0) current = 0;
  if (maxDepth > 0 && current > maxDepth) return {cend(),current};

  const_iterator i = find(cmd);

  if (i != cend()) {
    // Found the command in this.commands vector
    return {i, ++current};
  }

  for (const_iterator j = cbegin(); j != cend(); j++) {
    const_search_depth d = j->search(cmd, maxDepth, current);
    if (d.first != j->cend()) {
      d.second++;
      return d;
    }
  }

  return {cend(),current};
}

BGCommand::iterator BGCommand::command(const BGString& _n, bool addIfMissing) {
  if (!_n) return end();
  if (!hasCommand(_n) && addIfMissing) {
    BGCommand cmd = BGCommand(_n);
    addCommand(cmd);
  }
  return find(_n);
}

BGCommand::add_result BGCommand::addCommand(const BGCommand& c) {
  if (!c.name) { printf("Invalid command param\n"); return {end(), false}; }

  bool added = false;

  iterator i = end();
  if (!hasCommand(c)) {
    i = commands.insert(end(), c);
    if (i != end()) {
      i->setParent(*this);
      added = true;
#if TESTING
      // Command %s (%p) added subcommand: %s (%p)
      BGString addMsg("Command");
      addMsg.setPreAppend(@" ");

      addMsg += name;

      if (_identifier) {
        addMsg.appendFormat(@"(%lu)", _identifier);
      } else {
        addMsg.appendFormat(@"(%p)", this);
      }

      addMsg += "added subcommand:";
      addMsg += c.name;

      if (i->_identifier) {
        addMsg.appendFormat(@"(%lu)", i->_identifier);
      } else {
        addMsg.appendFormat(@"(%p)", &(*i));
      }

      addMsg += "\n";

      addMsg.print();
#endif
    }
  }

  return {i,added};
}

BGCommand::iterator BGCommand::removeCommand(const BGCommand& _c)                               { return commands.erase(find(_c.name)); }
BGCommand::iterator BGCommand::addCommands(BGCommandVector& _c)                                 { return commands.insert(cend(), _c.begin(), _c.end()); }
BGCommandVector::size_type BGCommand::count() const                                             { return commands.size(); }

void BGCommand::setOptions(const BGOptionDefinitionVector& rs)                                  { for (auto const& opt:rs) addOption(opt); _needsOptionsReset = true; }
void BGCommand::addOption(const GBOptionDefinition& rs)                                         { optionDefinitions.push_back(rs); _needsOptionsReset = true; }
void BGCommand::removeOption(const GBOptionDefinition& rs)                                      { optionDefinitions.remove(rs); _needsOptionsReset = true; }
void BGCommand::removeOption(BGOptionDefinitionVector::size_type __n)                           { optionDefinitions.remove(__n); _needsOptionsReset = true; }
GBOptionDefinition& BGCommand::optionAt(BGOptionDefinitionVector::size_type __n)                { return optionDefinitions[__n]; }
const GBOptionDefinition& BGCommand::optionAt(BGOptionDefinitionVector::size_type __n) const    { return optionDefinitions[__n]; }

void BGCommand::setName(const BGString& rs)                                                     { if (rs.valid()) name = rs; _initNameDeps(); }
BGString BGCommand::getName() const                                                             { return name; }
void BGCommand::setDescription(BGCommandStringBlock descriptionBlock)                           { if (descriptionBlock != NULL) description = descriptionBlock(*this); }
BGString BGCommand::getDescription() const                                                      { return description; }
void BGCommand::setSyntax(BGCommandStringBlock syntaxBlock)                                     { if (syntaxBlock != NULL) syntax = syntaxBlock(*this); }
BGString BGCommand::getSyntax() const                                                           { return syntax; }
void BGCommand::setRunBlock(BGCommandRunBlock __r) {
  runBlock = __r;
  if (runBlock != NULL) {
    setRunFunction(NULL);
  }
}
void BGCommand::setRunFunction(BGCommandRunFunction __r) {
  runFunction = __r;
  if (runFunction != NULL) {
    setRunBlock(NULL);
  }
}

int BGCommand::run(BGStringVector& args) {
  if (runBlock != NULL) return runBlock(args, settings, *this);
  if (runFunction != NULL) return runFunction(args, settings, *this);
  return -1;
}

void BGCommand::registerDefinitions() {
  if (!_needsOptionsReset) return;
  _needsOptionsReset = false;

  optionsHelper = [GBOptionsHelper new];
  parser = [GBCommandLineParser new];

  for (auto const& def:optionDefinitions) {
    [optionsHelper registerOption:def.shortOption long:def.longOption description:def.description flags:def.flags];
  }

  [optionsHelper registerOptionsToCommandLineParser:parser];
}

void BGCommand::setSettingsWithNameAndParent(const BGString& _n, GBSettings* _s) {
  if (!_n || _n.is_equal({_s.name})) return;
  settings = [GBSettings commandSettingsWithName:_n parent:_s];
}

bool BGCommand::parse(BGStringVector& args) {
  __block bool valid = true;
  GBCommandLineParseBlock parseBlock = ^(GBParseFlags flags, NSString *option, id value, BOOL *stop) {
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

bool BGCommand::parse(BGStringVector& args, GBCommandLineParseBlock parse_block) {
  registerDefinitions();
  return [parser parseOptionsWithArguments:[NSArray stringsFromStringVector:&args] commandLine:name block:parse_block];
}

BGCommand& BGCommand::parseCommand(BGStringVector& args) {
  if (args.empty()) {
    return *this;
  }

  BGString cmdString = args.front();

  if (cmdString == "help") {
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

BGString& BGCommand::helpString() {
  registerDefinitions();

  int spacing = 4;
  BGString help;

  help.setPostAppend(@"\n");

  // Command name
  help.addNewline();
  help += @"NAME:";
  help.appendFormat(@"%*s%@", spacing, "", name.fString);

  // Command synopsis
  if (!isAppCommand()) {
    if (syntax.valid()) {
      help.addNewline();
      help += @"SYNOPSIS:";
      help.appendFormat(@"%*s%@", spacing, "", syntax.fString);
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
      const BGCommand& command = *i;
      size_t length = command.name.size();
      longest = MAX(longest, length);
    }

    for (auto const& command:commands) {
      BGString subcommand;
      subcommand.appendFormat(@"%*s%@", spacing, "", command.name.fString);
      size_t diff = longest - command.name.size() + spacing;
      subcommand.appendFormat(@"%*s", (int)diff, "");
      subcommand += command.description;
      help += subcommand;
    }
  }

  // List of options
  if (optionDefinitions.size()) {
    help.addNewline();
    help += @"OPTIONS:";
    help += optionDefinitions.helpString(spacing);
  }

  // Footer

  return *(new BGString(help));
}

void BGCommand::printHelp(int exitVal) {
  BGString help = helpString();
  help.print();
  exit(exitVal);
}

// TODO: clear()
void BGCommand::clear() {
  nameWrapper = 0;
  _isAppCommand = 0;
  _identifier = 0;
  _needsOptionsReset = 0;
  parent = nullptr;
  name.zero();
  commands.clear();
  optionDefinitions.clear();
  optionsHelper = nil;
  settings = nil;
  parser = nil;
  tag = 0;
  description.zero();
  syntax.zero();
  runBlock = NULL;
}

BGString& BGCommand::inspect(int leadingSpaces) const {
  BGString info;
  int gen = generationDepth();
  int prespace = leadingSpaces * (gen - 1);

  info.setPreAppend([NSString stringWithFormat:@"%*s", MAX(prespace, 0), ""]);
  info.setPostAppend(@"\n");

  info.append(this->name);

  if (identifier()) {
    info.appendFormat(@"Identifier: %lu", this->identifier());
  }
  
  if (tag) {
    info.appendFormat(@"Tag: %lu", this->tag);
  }

  if (gen) {
    info.appendFormat(@"Generation: %d", gen);
  }

  if (this->count()) {
    info.appendFormat(@"Sub-Commands (%lu):", this->count());
    for (auto const& command:commands) {
      info.appendFormatOnly(@"%@", command.inspect(leadingSpaces).fString);
    }
  }

  return *(new BGString(info));
}
