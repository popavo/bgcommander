#ifndef __BG_COMMAND_H__
#define __BG_COMMAND_H__

#import "BGCommander.h"

@class GBOptionsHelper;
@class GBSettings;
@class GBCommandLineParser;

#define CommandIvars \
  name(), description(), syntax(), tag(), commands(), optionDefinitions(), optionsHelper(nil), settings(nil), parser(nil), runBlock(NULL), runFunction(NULL), \
  nameWrapper(), _isAppCommand(), _identifier(), _needsOptionsReset(true), parent(nullptr), addHelpToken()

BG_NAMESPACE

class Command {
public:
  typedef std::vector<Command> CommandVector;
  typedef int (^ CommandRunBlock)(StringVector args, GBSettings* settings, Command& command);
  typedef int (* CommandRunFunction)(StringVector args, GBSettings* settings, Command& command);
  typedef StringRef& (^ CommandStringBlock)(const Command& command);
  typedef typename CommandVector::iterator iterator;
  typedef typename CommandVector::const_iterator const_iterator;
  typedef typename CommandVector::size_type size_type;
  typedef std::pair<iterator, bool> add_result;
  typedef std::pair<iterator, NSInteger&> search_depth;
  typedef std::pair<const_iterator, NSInteger&> const_search_depth;
  typedef const char* const_char;

  static Command& AppCommand;

  StringRef name;
  StringRef description;
  NSInteger tag;

  CommandVector commands;
  OptionDefinitionVector optionDefinitions;
  StringVector syntax;

  GBOptionsHelper* optionsHelper;
  GBSettings* settings;
  GBCommandLineParser* parser;

  CommandRunBlock runBlock;
  CommandRunFunction runFunction;

protected:
  bool nameWrapper;
  bool _isAppCommand;
  NSUInteger _identifier;
  bool _needsOptionsReset;
  Command* parent;
  dispatch_once_t addHelpToken;

private:
  Command(const std::string& n) { _commonInit(n.c_str(), true); }
  static Command namedWrapper(const StringRef& n) { return Command(std::string(n.c_str())); }

public:
  static Command& sharedAppCommand();
  
  Command() : CommandIvars { _commonInit(name); _finishInit(); }
  Command(Command&& rs);
  Command(const Command& rs);
  Command(const StringRef& _s, const StringRef& _d="", const OptionDefinitionVector& _o={});
  Command(const_char _s, const StringRef& _d="", const OptionDefinitionVector& _o={});
  Command(NSString* _s, const StringRef& _d="", const OptionDefinitionVector& _o={});

  Command& operator =(const Command& rs);
  Command& operator =(Command&& rs);

  EQ_OPERATOR(const_char, name.is_equal(rs))
  EQ_OPERATOR(const StringRef&, name.is_equal(rs))
  EQ_OPERATOR(const Command&, is_equal(rs))
  bool operator !() const;
  bool valid() const;
  bool is_equal(const Command& rs) const;

  bool isAppCommand() const;
  NSUInteger identifier() const;
  std::size_t hash() const;

  int generationDepth() const;
  void setParent(Command& p);
  bool hasChildren() const;

  iterator begin();
  iterator end();
  const_iterator cbegin() const;
  const_iterator cend() const;

  Command& operator [](const StringRef& _n);
  const Command& operator[](const StringRef& _n) const;

  bool                  hasCommand(const StringRef& name) const;
  bool                  hasCommand(const Command& rs) const;

  iterator              find(const Command& _c);
  const_iterator        find(const Command& _n) const;
  iterator              find(const StringRef& _n);
  const_iterator        find(const StringRef& _n) const;

  iterator              search(const StringRef& name);
  const_iterator        search(const StringRef& name) const;
  search_depth          search(const StringRef& name, NSInteger maxDepth, NSInteger& current);
  const_search_depth    search(const StringRef& name, NSInteger maxDepth, NSInteger& current) const;
  search_depth          search(const Command& name, NSInteger maxDepth, NSInteger& current);
  const_search_depth    search(const Command& name, NSInteger maxDepth, NSInteger& current) const;

  iterator              command(const StringRef& _n, bool addIfMissing=true);
  add_result            addCommand(const Command& __c);
  add_result            addCommand(Command&& _c);

  iterator              removeCommand(const Command& _c);
  iterator              addCommands(CommandVector& _c);

  size_type count() const;

  void resetParentRefs();

  void setOptions(const OptionDefinitionVector& rs);
  void addOption(const GBOptionDefinition& rs);
  void removeOption(const GBOptionDefinition& rs);
  void removeOption(OptionDefinitionVector::size_type __n);
  GBOptionDefinition& optionAt(OptionDefinitionVector::size_type __n);
  const GBOptionDefinition& optionAt(OptionDefinitionVector::size_type __n) const;

  void setSyntaxes(const StringVector& rs);
  void addSyntax(const StringRef& rs);
  void removeSyntax(const StringRef& rs);
  void removeSyntax(StringVector::size_type __n);
  StringRef& syntaxAt(StringVector::size_type __n);
  const StringRef& syntaxAt(StringVector::size_type __n) const;

  StringRef commandString();

  void registerDefinitions();
  void setSettingsWithNameAndParent(const StringRef& _n, GBSettings* _s);

  void        setName(const StringRef& rs);
  StringRef    getName() const;
  void        setDescription(CommandStringBlock descriptionBlock);
  StringRef    getDescription() const;
  
  void setRunBlock(CommandRunBlock __r);
  void setRunFunction(CommandRunFunction __r);

  virtual int run(StringVector& args);

  bool parse(StringVector& args);
  bool parse(StringVector& args, GBCommandLineParseBlock parse_block);

  Command& parseCommand(StringVector& args);

  StringRef helpString();
  void printHelp(int exitVal = 0);
  void printVersion(int exitVal = 0);
  void printSettings(int exitVal = INT32_MIN);

  StringRef inspect(int leadingSpaces = 0) const;

private:
  void _initIvars();
  void _initNameDeps();
  void _commonInit(const StringRef& _s, bool _nw = false);
  void _finishInit();
  void clear();

  void _copyAssign(const Command& rs);
  void _moveAssign(Command&& rs);

  friend class Commander;
};

typedef Command::CommandVector CommandVector;

BG_NAMESPACE_END

#endif