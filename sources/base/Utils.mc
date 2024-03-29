class Utils {
    static function replaceNull(nullableValue, defaultValue) {
        if (nullableValue != null) {
            return nullableValue;
        } else {
            return defaultValue;
        }
    }

    static function format_distance(distance, useMetric) {
        var factor = 1000;
        var smallunitfactor = 1000;
        var unit = "KM";
        var smallunit = "M";

        if (!useMetric) {
            factor = 1609;
            smallunitfactor = 1760;
            unit = "MI";
            smallunit = "YD";
        }

        if ((distance / factor) >= 1) {
            return [ ((distance * 1.0) / (factor * 1.0)).format("%0.2f"), unit];
        } else {
            return [ (distance / factor * smallunitfactor).toNumber() + "", smallunit];
        }
    }

    static function format_duration(seconds) {
        var hh = seconds / 3600;
        var mm = seconds / 60 % 60;
        var ss = seconds % 60;

        if (hh != 0) {
            return hh + ":" + mm.format("%02d") + ":" + ss.format("%02d");
        } else {
            return mm + ":" + ss.format("%02d");
        }
    }

  function convert_speed_pace(speed, useMetric, useSpeed) {
    if (speed != null && speed > 0) {
      var factor = useSpeed ? (useMetric ? 3.6 : 2.23694) : (useMetric ? 1000.0 : 1609.0);
      var secondsPerUnit = useSpeed ? speed * factor : factor / speed;
      if(!useSpeed){
        secondsPerUnit = (secondsPerUnit + 0.5).toNumber();
        var minutes = (secondsPerUnit / 60);
        var seconds = (secondsPerUnit % 60);
        return minutes + ":" + seconds.format("%02u");
      } else {
        return secondsPerUnit.format("%0.2f");
      }
    } else {
      return useSpeed ? "0.00" : "0:00";
    }
  }

  function split(s, sep, number) {
    var tokens = [];

    var found = s.find(sep);
    while (found != null) {
      var token = s.substring(0, found);
      tokens.add(number ? token.toNumber() : token);
      s = s.substring(found + sep.length(), s.length());
      found = s.find(sep);
    }

    tokens.add(number ? s.toNumber() : s);

    return tokens;
  }
}