import tefutefuLine.core.botKeys,
       tefutefuLine.core.sender;
import tefutefuLine.reactions.reaction;

import std.stdio,
       std.json;
import core.thread;
import vibe.d;

Reactions reactions;

static JSONValue getJsonData(JSONValue parsedJson, string key) {
  return key in parsedJson.object ? parsedJson.object[key] : JSONValue.init;
}

static JSONValue getJsonDataWithPath(JSONValue data, string path) {
  return path.split("/").length == 0 ? data : getJsonDataWithPath(data.object[path.split("/")[0]], path.split("/")[1..$].join("/"));
}

void botProc(HTTPServerRequest req, HTTPServerResponse res) {
  writeln("Receive!");
  foreach (result; parseJSON(req.json.to!string).object["result"].array) {
    auto content = result.object["content"];
    string text  = content.object["text"].str;
    writeln("recieve: ", text);
    reactions.reaction(result);
  }
}

void init() {
  BotKeys keys = BotKeys(
                    "Your Channel ID",
                    "Your Channel Secret",
                    "Your MID"
                  );
  Sender sender = new Sender(keys);
  reactions = new Reactions(sender);
  reactions.addNewReaction("weather", new class Reaction {
      import std.net.curl,
             std.datetime,
             std.format,
             std.array,
             std.string,
             std.stdio,
             std.regex,
             std.conv,
             std.file,
             std.json,
             std.uri;
             
      string baseUrl = "https://query.yahooapis.com/v1/public/yql";
      string[string] jTables;

      this() {
        jTables = [
          "0" : "竜巻",
          "1" : "台風",
          "2" : "台風",
          "3" : "激しい雷雨",
          "4" : "雷雨",
          "5" : "雨まじりの雪",
          "6" : "雨まじりのみぞれ",
          "7" : "雪混じりのみぞれ",
          "8" : "雨氷",
          "9" : "霧雨",
          "10" : "着氷性の雨",
          "11" : "にわか雨",
          "12" : "にわか雨",
          "13" : "しゅう雪",
          "14" : "小雪",
          "15" : "地吹雪",
          "16" : "雪",
          "17" : "あられ",
          "18" : "みぞれ",
          "19" : "ほこり",
          "20" : "濃霧",
          "21" : "薄霧",
          "22" : "smoky",
          "23" : "強風",
          "24" : "強風",
          "25" : "低温",
          "26" : "くもり",
          "27" : "くもりのち晴れ",
          "28" : "くもりのち晴れ",
          "29" : "晴れ時々くもり",
          "30" : "晴れ時々くもり",
          "31" : "晴れ",
          "32" : "晴れ",
          "33" : "快晴",
          "34" : "快晴",
          "35" : "雨まじりのひょう",
          "36" : "高温",
          "37" : "ところにより雷雨",
          "38" : "広い範囲で雷雨",
          "39" : "広い範囲で雷雨",
          "40" : "広い範囲でにわか雨",
          "41" : "大雪",
          "42" : "広い範囲でにわか雪",
          "43" : "大雪",
          "44" : "晴れ時々くもり",
          "45" : "雷雨",
          "46" : "にわか雪",
          "47" : "ところにより雷雨",
          "3200" : "エラー 利用不可"
        ];
      }

      override bool isTarget(JSONValue result) {
        auto content = result.object["content"];
        string from  = content.object["from"].str;
        string text  = content.object["text"].str;

        import std.regex;
        return text.match(regex(r"天気")) ? true : false;
      }

      override string reaction(JSONValue result) {
        writeln("[parseStatus] -> [weather]");
        auto content = result.object["content"];
        string text  = content.object["text"].str;

        string place;
        JSONValue jr;
        JSONValue[] forecasts;

        string printForcast(JSONValue forecast) {
          string code = forecast.getJsonData("code").str;
          string[] dates = forecast.getJsonData("date").str.split;
          string dayS   = dates[0],
                 monthS = dates[1],
                 yearS  = dates[2];
          Appender!string dateStr = appender!string();
          formattedWrite(dateStr, "%s-%s-%s 00:00:00", yearS, monthS, dayS);
          SysTime time = SysTime.fromSimpleString(dateStr.data);
          string tHigh = forecast.getJsonData("high").str,
                 tLow  = forecast.getJsonData("low").str;
          string[] wdays = ["日", "月", "火", "水", "木", "金", "土"];

          int month = cast(int)time.month,
              day   = cast(int)time.day;
          string wday = wdays[cast(int)time.dayOfWeek];

          Appender!string returnString = appender!string;

          formattedWrite(returnString, "%sの%d月%d日%s曜日の天気は%s\\n最高気温は%s℃ 最高気温は%s℃", place, month, day, wday, jTables[code], tHigh, tLow);

          return returnString.data;
        }

        if (text.match(regex("今日|きょう|明日|あした|明後日|あさって|明々後日|しあさって|週間"))) {
          string rText = text.replace(regex("(今日|きょう|明日|あした|明後日|あっさて|明々後日|しあさって|週間)の"), "");
          auto m = matchAll(rText, regex(r"(\S+)の"));

          if (!m.empty) {
            place = m.front.hit.replaceAll(regex("の"), "");

            Appender!string query = appender!string;
            formattedWrite(query, "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"%s\") and u=\"c\"", place);

            string res = get(baseUrl ~ "/?q=" ~ encodeComponent(query.data) ~ "&u=c&format=json").to!string;

            //writeln("RESULT: ", result);

            jr = parseJSON(res);
            forecasts = jr.getJsonDataWithPath("query/results/channel/item/forecast").array;
          } else {
            return "ごめんね！><地名がわからないの！\\b \\\"<地名>の<今日|明日|明後日|明々後日|週間>の天気を教えて！\\\"\\n って言ってみてほしいな！";
          }
          
          if (text.match(regex("今日|きょう"))) {
            if (text.match("詳細")) {
              //今日の詳細天気
              string humidity = jr.getJsonDataWithPath("query/results/channel/atmosphere/humidity").str,
                     sunrise  = jr.getJsonDataWithPath("query/results/channel/astronomy/sunrise").str,
                     sunset   = jr.getJsonDataWithPath("query/results/channel/astronomy/sunset").str;
              JSONValue condition = jr.getJsonDataWithPath("query/results/channel/item/condition");

              Appender!string returnString = appender!string;

              formattedWrite(returnString, "%sの現在の天気は%s \\n現在の気温は %s℃、 湿度 %s%% \\n今日の日の出は%s、日の入りは%s", place, jTables[condition.getJsonData("code").str], condition.getJsonData("temp").str, humidity, sunrise, sunset);

              return returnString.data;
            } else {
              return printForcast(forecasts[0]);
            }
          } else if (text.match(regex("明日|あした"))) {
            return printForcast(forecasts[1]);
          } else if (text.match(regex("明後日|(し)!あさって"))) {
            return printForcast(forecasts[2]);
          } else if (text.match(regex("明々後日|しあさって"))) {
            return printForcast(forecasts[3]);
          } else if (text.match(regex("週間"))) {
            //週間天気
            string returnString;

            foreach (JSONValue forecast; jr.getJsonDataWithPath("query/results/channel/item/forecast").array[0..8]) {
              returnString ~= "-----------------------\\n" ~ printForcast(forecast) ~ "\\n"; 
            }

            return returnString;
          }
        } else {
          auto m = matchAll(text, regex(r"(\S+)の"));
          if (!m.empty) {
            place = m.front.hit.replaceAll(regex("の"), "");

            Appender!string query = appender!string;
            formattedWrite(query, "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text=\"%s\") and u=\"c\"", place);

            string res = get(baseUrl ~ "/?q=" ~ encodeComponent(query.data) ~ "&u=c&format=json").to!string;

            writeln("RESULT: ", res);

            jr = parseJSON(res);
            forecasts = jr.getJsonDataWithPath("query/results/channel/item/forecast").array;
          } else {
            //error 

            return "ごめんね！><地名がわからないの！\\b \\\"<地名>の<今日|明日|明後日|明々後日|週間>の天気を教えて！\\\"\\n って言ってみてほしいな！";
          }

          if (text.match("詳細")) {
            //今日の詳細天気
            string humidity = jr.getJsonDataWithPath("query/results/channel/atmosphere/humidity").str,
                   sunrise  = jr.getJsonDataWithPath("query/results/channel/astronomy/sunrise").str,
                   sunset   = jr.getJsonDataWithPath("query/results/channel/astronomy/sunset").str;
            JSONValue condition = jr.getJsonDataWithPath("query/results/channel/item/condition");

            Appender!string returnString = appender!string;

            formattedWrite(returnString, "%sの現在の天気は%s \\n現在の気温は %s℃、 湿度 %s%% \\n今日の日の出は%s、日の入りは%s", place, jTables[condition.getJsonData("code").str], condition.getJsonData("temp").str, humidity, sunrise, sunset);

            return returnString.data;
          } else {
            return printForcast(forecasts[0]);
          }
        }


        return "";
      }
  });

  reactions.addNewReaction("omikuji", new class Reaction {
      import std.regex;

      override bool isTarget(JSONValue result) {
        auto content = result.object["content"];
        string from  = content.object["from"].str;
        string text  = content.object["text"].str;

        return text.match(regex("おみくじ")) ? true : false;
      }

      override string reaction(JSONValue _) {
      writeln("[parseStatus] -> omikuji");
      import std.random;
      Mt19937 mt;
      string result;

      mt.seed(unpredictableSeed);

      switch (mt.front % 20 + 1) {
        case 1: .. case 2:
                result = "大吉です！ おめでとうございます♪";
                break;
        case 3: .. case 4:
                result = "大凶です (´・ω・`)。 ドンマイ！";
                break;
        case 5: .. case 8:
                result = "中吉です！";
                break;
        case 9: .. case 12:
                result = "吉です！";
                break;
        case 13: .. case 17:
                 result = "末吉です";
                 break;
        case 18: .. case 20:
                 result = "凶です ドンマイ！";
                 break;
        default: break;
      }
      
      return result;
    } 
  });

  reactions.addNewReaction("echo", new class Reaction {
    override bool isTarget(JSONValue _) {
      return true;
    }

    override string reaction(JSONValue result) {
      auto content = result.object["content"];
      string from  = content.object["from"].str;
      string text  = content.object["text"].str;

      return "Server Echo にゃん！ : " ~ text;
    }
  });

  reactions.setDefaultReaction("echo");

  writeln("Ready!");
}

void works(HTTPServerRequest req, HTTPServerResponse res) {
  res.writeBody("works!", "text/plain");
}
static this() {
  auto router = new URLRouter;
  router.post("/", &botProc);
  router.post("/works", &works);
  router.get("/works", &works);

  auto settings = new HTTPServerSettings;
  settings.port = 4567;
  settings.tlsContext = createTLSContext(TLSContextKind.server);
  settings.tlsContext.useTrustedCertificateFile("chain.pem");
  settings.tlsContext.useCertificateChainFile("fullchain.pem");
  settings.tlsContext.usePrivateKeyFile("privkey.pem");

  listenHTTP(settings, router);

  init;
}
