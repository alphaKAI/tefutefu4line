import tefutefuLine.core.botKeys,
       tefutefuLine.core.sender;
import tefutefuLine.reactions.reaction;

import std.stdio,
       std.json;
import core.thread;
import vibe.d;
import weatherd;

Reactions reactions;

void botProc(HTTPServerRequest req, HTTPServerResponse res) {
  writeln("Receive!");
  foreach (result; parseJSON(req.json.to!string).object["result"].array) {
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
      WeatherD weather;
       
      struct Weather {
        string place,
               date,
               weather,
               tempMax,
               tempMin;
      }

      this() {
        weather = new WeatherD;
      }

      override bool isTarget(JSONValue result) {
        auto content = result.object["content"];
        string from  = content.object["from"].str;
        string text  = content.object["text"].str;

        import std.regex;
        return text.match(regex(r"(今日|明日|明後日)?.*天気")) ? true : false;
      }

      override string reaction(JSONValue result) {
        import std.regex;
        
        writeln("[parseStatus] -> [weather]");
        string pref,
               city;
        bool findFlag;

        auto content = result.object["content"];
        string from  = content.object["from"].str;
        string text  = content.object["text"].str;

        foreach (ePref, cities; weather.prefs) {
          foreach (eCity; cities.keys) {
            if (match(text, regex(eCity))) {
              pref = ePref;
              city = eCity;
              findFlag = true;
              break;
            }

            if (findFlag) {
              break;
            }
          }
        }

        if (!findFlag) {//NotFound the place
          return "ごめんね！ その地名は登録されていないの！><";
        } else {
          string[] dateLabels = ["今日", "明日", "明後日"];
          string dateLabel    = "今日";
          Weather weatherStruct;

          foreach (date; dateLabels) {
            if (match(text, regex(date))) {
              dateLabel = date;
              break;
            }
          }

          foreach (forecast; weather.getWeatherData(pref, city).object["forecasts"].array) {
            if (forecast.object["dateLabel"].str == dateLabel) {
              weatherStruct.place = pref ~ city;
              weatherStruct.date  = dateLabel ~ "(" ~ forecast.object["date"].str ~ ")";
              weatherStruct.weather = forecast.object["telop"].str;
              weatherStruct.tempMax = getJsonDataWithPath(forecast, "temperature/max") == "null"
                ? "null" : getJsonDataWithPath(forecast, "temperature/max/celsius").removechars("\"");
              weatherStruct.tempMin = getJsonDataWithPath(forecast, "temperature/min") == "null"
                ? "null" : getJsonDataWithPath(forecast, "temperature/min/celsius").removechars("\"");

              return weatherStruct.place ~ "の" ~ weatherStruct.date ~ "の天気は" ~ weatherStruct.weather
                  ~ (weatherStruct.tempMax == "null" || weatherStruct.tempMin == "null" ?
                      "です♪" :
                      "で 最高気温/最低気温は" ~ weatherStruct.tempMax ~ "℃/" ~ weatherStruct.tempMin ~ "℃ です♪");
            }
          }
        }
        return "";
      }

      string getJsonDataWithPath(JSONValue data, string path){
        return path.split("/").length == 0 ? data.to!string : getJsonDataWithPath(data.object[path.split("/")[0]], path.split("/")[1..$].join("/"));
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

      return "さーばーえこーにゃん！ : " ~ text;
    }
  });

  reactions.setDefaultReaction("echo");

  writeln("Ready!");
}

static this() {
  auto router = new URLRouter;
  router.post("/", &botProc);

  auto settings = new HTTPServerSettings;
  settings.port = 4567;
  settings.tlsContext = createTLSContext(TLSContextKind.server);
  settings.tlsContext.useTrustedCertificateFile("chain.pem");
  settings.tlsContext.useCertificateChainFile("fullchain.pem");
  settings.tlsContext.usePrivateKeyFile("privkey.pem");

  listenHTTP(settings, router);

  init;
}
