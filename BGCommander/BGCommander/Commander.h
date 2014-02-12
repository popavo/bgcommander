#ifndef __BG_COMMANDER_H__
#define __BG_COMMANDER_H__

#import "BGCommander.h"

BG_NAMESPACE

class Commander;

extern Commander& commander;

class Commander {
public:
  typedef typename Command::iterator iterator;
  typedef typename Command::const_iterator const_iterator;
  typedef typename Command::size_type size_type;
  typedef typename Command::add_result add_result;
  typedef typename Command::search_depth search_depth;
  typedef typename Command::const_search_depth const_search_depth;

private:
  Commander() { }

public:
  static Commander& sharedCommander();

  CommandVector& commands();

  Command& operator [](const StringRef& _n);
  const Command& operator [](const StringRef& _n) const;

  iterator              begin();
  iterator              end();
  const_iterator        cbegin() const;
  const_iterator        cend() const;

  bool                  hasCommand(const Command& rs) const;
  iterator              find(const StringRef& _n);
  const_iterator        find(const StringRef& _n) const;
  Command&              command(const StringRef& _n, bool addIfMissing=true);
  Command&              addCommand(const Command& __c);
  add_result            addCommand(const Command& command, const Command& parent);

#if CMD_USE_VARIADICS
  template <class... _Args>
  Command& addCommand(_Args&&... __args);
#endif
  
  iterator              removeCommand(const Command& _c);

  search_depth          search(const StringRef& name, NSInteger maxDepth);
  const_search_depth    search(const StringRef& name, NSInteger maxDepth) const;
  search_depth          search(const Command& _c, NSInteger maxDepth);
  const_search_depth    search(const Command& _c, NSInteger maxDepth) const;

  iterator command(StringVector command_path);

  void resetAllParentRefs();

  int run(StringVector& args = [[[NSProcessInfo processInfo] arguments] stringVector].from(1));
};

class CommanderAutoRunner {
  Commander& _commander;
  bool _exit;
public:
  CommanderAutoRunner(Commander& _c = Commander::sharedCommander(), bool _e = true) : _commander(_c), _exit(_e) { }
  ~CommanderAutoRunner() { int status = _commander.run(); if (_exit) exit(status); }
};

#if CMD_USE_VARIADICS

template<class... _Args>
Command& Commander::addCommand(_Args&&... __args) {
  Command cmd(std::forward<_Args>(__args)...);
  Command::AppCommand.addCommand(cmd);
  return *find(cmd.name);
}

#endif

BG_NAMESPACE_END

#endif