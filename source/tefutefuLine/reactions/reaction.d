module tefutefuLine.reactions.reaction;
import tefutefuLine.core.sender;

import std.algorithm,
       std.regex,
       std.json;

abstract class Reaction {
  bool isTarget(JSONValue);
  string reaction(JSONValue);
}

class Reactions {
  private Reaction[string] reactions;
  private Sender sender;
  private string _default;
  private bool enableDefault;

  this(Sender _sender) {
    sender = _sender;
  }

  bool existReaction(string key) {
    return reactions.keys.any!(e => e == key);
  }

  bool addNewReaction(string name, Reaction reaction) {
    if (existReaction(name)) {
      return false;
    } else {
      reactions[name] = reaction;
      return true;
    }
  }

  void reaction(JSONValue parsedJSON) {
    bool flag;
    foreach (name, thisReaction; reactions) {
      if (enableDefault && name == _default) {
        continue;
      }

      if (thisReaction.isTarget(parsedJSON)) {
        flag = true;
        sender.sendMessageTo(parsedJSON.object["content"].object["from"].str, thisReaction.reaction(parsedJSON));
        break;
      }
    }

    if (!flag && enableDefault) {
      sender.sendMessageTo(parsedJSON.object["content"].object["from"].str, reactions[_default].reaction(parsedJSON));
    }
  }

  void setDefaultReaction(string name) {
    if (existReaction(name)) {
      _default = name;
      enableDefault = true;
    }
  }
}
