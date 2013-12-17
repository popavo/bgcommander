#ifndef __BG_COMMAND_H__
#define __BG_COMMAND_H__

#import "GBOptionsHelper.h"
#import "GBSettings.h"
#import "GBCommandLineParser.h"
#import "BGOptionDefinitionVector.h"

#define BGCommandIvars \
  name(), description(), syntax(), tag(), commands(), optionDefinitions(), optionsHelper(nil), settings(nil), parser(nil), runBlock(NULL), runFunction(NULL), \
  nameWrapper(), _isAppCommand(), _identifier(), _needsOptionsReset(true), parent(nullptr)


class BGCommand {
public:
  typedef std::vector<BGCommand> BGCommandVector;
  typedef int (^ BGCommandRunBlock)(BGStringVector args, GBSettings* options, BGCommand& command);
  typedef int (* BGCommandRunFunction)(BGStringVector args, GBSettings* options, BGCommand& command);
  typedef BGString& (^ BGCommandStringBlock)(const BGCommand& command);
  typedef typename BGCommandVector::iterator iterator;
  typedef typename BGCommandVector::const_iterator const_iterator;
  typedef typename BGCommandVector::size_type size_type;
  typedef std::pair<iterator, bool> add_result;
  typedef std::pair<iterator, NSInteger&> search_depth;
  typedef std::pair<const_iterator, NSInteger&> const_search_depth;
  typedef const char* const_char;

  static BGCommand& AppCommand;

  BGString name;
  BGString description;
  BGString syntax;
  NSInteger tag;

  BGCommandVector commands;
  BGOptionDefinitionVector optionDefinitions;

  GBOptionsHelper* optionsHelper;
  GBSettings* settings;
  GBCommandLineParser* parser;

  BGCommandRunBlock runBlock;
  BGCommandRunFunction runFunction;

protected:
  bool nameWrapper;
  bool _isAppCommand;
  NSUInteger _identifier;
  bool _needsOptionsReset;
  BGCommand* parent;

private:
  BGCommand(const std::string& n) : name(n.c_str()), nameWrapper(true) { }
  static BGCommand& namedWrapper(const BGString& n) { return *(new BGCommand(std::string(n.c_str()))); }

public:
  static BGCommand& sharedAppCommand();
  
  BGCommand() : BGCommandIvars { _commonInit(name); }
  BGCommand(BGCommand&& rs);
  BGCommand(const BGCommand& rs);
  BGCommand(const BGString& _s, const BGString& _d="", const BGOptionDefinitionVector& _o={});
  BGCommand(const_char _s, const BGString& _d="", const BGOptionDefinitionVector& _o={});
  BGCommand(NSString* _s, const BGString& _d="", const BGOptionDefinitionVector& _o={});

  BGCommand& operator =(const BGCommand& rs);
  BGCommand& operator =(BGCommand&& rs);

  EQ_OPERATOR(const_char, name.is_equal(rs))
  EQ_OPERATOR(const BGString&, name.is_equal(rs))
  EQ_OPERATOR(const BGCommand&, is_equal(rs))
  bool operator !() const;
  bool valid() const;
  bool is_equal(const BGCommand& rs) const;

  bool isAppCommand() const;
  NSUInteger identifier() const;
  std::size_t hash() const;

  int generationDepth() const;
  void setParent(BGCommand& p);
  bool hasChildren() const;

  iterator begin();
  iterator end();
  const_iterator cbegin() const;
  const_iterator cend() const;

  BGCommand& operator [](const BGString& _n);
  const BGCommand& operator[](const BGString& _n) const;

  bool hasCommand(const BGString& name) const;
  bool hasCommand(const BGCommand& rs) const;

  iterator        find(const BGCommand& _c);
  const_iterator  find(const BGCommand& _n) const;
  iterator        find(const BGString& _n);
  const_iterator  find(const BGString& _n) const;

  iterator              search(const BGString& name);
  const_iterator        search(const BGString& name) const;
  search_depth          search(const BGString& name, NSInteger maxDepth, NSInteger& current);
  const_search_depth    search(const BGString& name, NSInteger maxDepth, NSInteger& current) const;
  search_depth          search(const BGCommand& name, NSInteger maxDepth, NSInteger& current);
  const_search_depth    search(const BGCommand& name, NSInteger maxDepth, NSInteger& current) const;

  iterator      command(const BGString& _n, bool addIfMissing=true);
  add_result    addCommand(const BGCommand& __c);
  iterator      removeCommand(const BGCommand& _c);
  iterator      addCommands(BGCommandVector& _c);

  BGCommandVector::size_type count() const;

  void resetParentRefs();

  void setOptions(const BGOptionDefinitionVector& rs);
  void addOption(const GBOptionDefinition& rs);
  void removeOption(const GBOptionDefinition& rs);
  void removeOption(BGOptionDefinitionVector::size_type __n);
  GBOptionDefinition& optionAt(BGOptionDefinitionVector::size_type __n);
  const GBOptionDefinition& optionAt(BGOptionDefinitionVector::size_type __n) const;

  void registerDefinitions();
  void setSettingsWithNameAndParent(const BGString& _n, GBSettings* _s);

  void        setName(const BGString& rs);
  BGString    getName() const;
  void        setDescription(BGCommandStringBlock descriptionBlock);
  BGString    getDescription() const;
  void        setSyntax(BGCommandStringBlock syntaxBlock);
  BGString    getSyntax() const;
  
  void setRunBlock(BGCommandRunBlock __r);
  void setRunFunction(BGCommandRunFunction __r);

  virtual int run(BGStringVector& args);

  bool parse(BGStringVector& args);
  bool parse(BGStringVector& args, GBCommandLineParseBlock parse_block);

  BGCommand& parseCommand(BGStringVector& args);

  BGString& helpString();
  void printHelp(int exitVal = 0);

  BGString& inspect(int leadingSpaces = 0) const;

private:
  void _initIvars();
  void _initNameDeps();
  void _commonInit(const BGString& _s);
  void clear();

  void _copyAssign(const BGCommand& rs);
  void _moveAssign(BGCommand&& rs);

protected:
  friend class BGCommander;
};

typedef BGCommand::BGCommandVector BGCommandVector;

namespace std {
  template<>
  struct hash<BGCommand> {
    size_t operator()(const BGCommand& __v) const {
      return __v.hash();
    }
  };

  template<>
  struct hash<BGCommandVector::const_iterator> {
    size_t operator()(BGCommandVector::const_iterator __v) {
      hash<BGCommand> hasher;
      return hasher(*__v);
    }
  };
}

#endif