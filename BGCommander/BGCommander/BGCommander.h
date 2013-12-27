#ifndef __BG_COMMANDER_H__
#define __BG_COMMANDER_H__

#import "BGCommand.h"

class BGCommander;

extern BGCommander& commander;

class BGCommander {
public:
  typedef typename BGCommand::iterator iterator;
  typedef typename BGCommand::const_iterator const_iterator;
  typedef typename BGCommand::size_type size_type;
  typedef typename BGCommand::add_result add_result;
  typedef typename BGCommand::search_depth search_depth;
  typedef typename BGCommand::const_search_depth const_search_depth;

private:
  int runResult;
  BGCommander();

public:
  static BGCommander& sharedCommander();

  BGCommandVector& commands();

  BGCommand& operator [](const BGString& _n);
  const BGCommand& operator [](const BGString& _n) const;

  iterator          begin();
  iterator          end();
  const_iterator    cbegin() const;
  const_iterator    cend() const;

  bool              hasCommand(const BGCommand& rs) const;
  iterator          find(const BGString& _n);
  const_iterator    find(const BGString& _n) const;
  BGCommand&        command(const BGString& _n, bool addIfMissing=true);
  BGCommand&        addCommand(const BGCommand& __c);
  add_result        addCommand(const BGCommand& command, const BGCommand& parent);
  iterator          removeCommand(const BGCommand& _c);

  void resetAllParentRefs();

  search_depth          search(const BGString& name, NSInteger maxDepth);
  const_search_depth    search(const BGString& name, NSInteger maxDepth) const;
  search_depth          search(const BGCommand& _c, NSInteger maxDepth);
  const_search_depth    search(const BGCommand& _c, NSInteger maxDepth) const;

  iterator command(BGStringVector command_path);

  int run();
};

class CommanderAutoRunner {
  BGCommander& _commander;
  bool _exit;
public:
  CommanderAutoRunner(BGCommander& _c = BGCommander::sharedCommander(), bool _e = true) : _commander(_c), _exit(_e) { }
  ~CommanderAutoRunner() { int status = _commander.run(); if (_exit) exit(status); }
};

#endif