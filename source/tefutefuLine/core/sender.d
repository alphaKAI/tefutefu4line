module tefutefuLine.core.sender;
import tefutefuLine.core.botKeys;
import std.net.curl,
       std.stdio;

class Sender {
  private BotKeys keys;

  this(BotKeys _keys) {
    keys = _keys;
  }

  void sendRequestWithJson(string sendJSON) {
    enum serverURL = "https://trialbot-api.line.me/v1/events";

    auto http = HTTP();
    with (keys) {
      foreach (key, value; 
          [
          "Content-Type"                 : "application/json; charset=UTF-8",
          "X-Line-ChannelID"             : LINE_CHANNEL_ID,
          "X-Line-ChannelSecret"         : LINE_CHANNEL_SECRET,
          "X-Line-Trusted-User-With-ACL" : LINE_CHANNEL_MID
          ]) {
        http.addRequestHeader(key, value);
      }
    }

    writeln("send -> ", sendJSON);
    post(serverURL, sendJSON, http);
  }

  void sendMessageTo(string to, string message) {
    writeln("to -> ", to);
    writeln("messagee -> ", message);
    string sendJSON = `
    {
      "to" : [` ~ "\"" ~ to ~ "\"" ~ `],
      "toChannel" : 1383378250,
      "eventType" : "138311608800106203",
      "content" : {
        "contentType" : 1,
        "toType" : 1,
        "text" : "` ~ message ~ `"
      }
    }`;

    sendRequestWithJson(sendJSON);
  }

}
