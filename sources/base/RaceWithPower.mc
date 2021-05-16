using Toybox.WatchUi;
using Toybox.Attention;
using Toybox.UserProfile;
using Toybox.AntPlus;
using Toybox.System as Sys;

class RaceWithPowerView extends WatchUi.DataField {
  hidden var sensor;
  hidden var paused = true;
  hidden var fonts;
  hidden var fontOffset;

  // [ Width, Center, 1st horizontal line, 2nd horizontal line
  // 3rd Horizontal line, 1st vertical, Second vertical, Radius,
  // Top Arc, Bottom Arc, Offset Target Y, Background rect height, Offset Target
  // X, Center mid field ]

  (:roundzero) const geometry =
      [ 218, 109, 77, 122, 167, 70, 161, 103, 114, 85, 27, 45, 30, 116 ];
  (:roundone) const geometry =
      [ 240, 120, 85, 135, 185, 77, 177, 105, 114, 96, 32, 50, 40, 127 ];
  (:roundtwo) const geometry =
      [ 260, 130, 91, 146, 201, 83, 192, 115, 124, 106, 37, 55, 45, 138 ];
  (:roundthree) const geometry =
      [ 280, 140, 98, 157, 216, 90, 207, 125, 134, 116, 42, 59, 50, 149 ];
  (:roundfour) const geometry =
      [ 390, 195, 140, 220, 300, 125, 289, 180, 189, 171, 45, 80, 55, 207 ];
  (:roundfive) const geometry =
      [ 360, 180, 127, 202, 277, 115, 266, 165, 174, 156, 50, 75, 52, 191 ];
  (:roundsix) const geometry =
      [ 416, 208, 147, 234, 320, 133, 308, 193, 202, 187, 55, 87, 60, 221 ];

  function initialize(strydsensor) {
    DataField.initialize();
    sensor = strydsensor;
  }

  function onTimerStart() { paused = false; }

  function onTimerStop() { paused = true; }

  function onTimerResume() { paused = false; }

  function onTimerPause() { paused = true; }

  function onTimerLap() {
  }

  function onTimerReset() {
  }

  (:highmem) function set_fonts() {
    if (Utils.replaceNull(Application.getApp().getProperty("I"), true)) {
      fontOffset = -4;
      fonts = [
        WatchUi.loadResource(Rez.Fonts.A), WatchUi.loadResource(Rez.Fonts.C),
        WatchUi.loadResource(Rez.Fonts.C), WatchUi.loadResource(Rez.Fonts.D),
        WatchUi.loadResource(Rez.Fonts.E), WatchUi.loadResource(Rez.Fonts.F)
      ];
    } else {
      fonts = [ 0, 1, 2, 3, 6, 8 ];
    }
  }

  (:lowmemlow) function set_fonts() { fonts = [ 0, 1, 2, 3, 6, 8 ]; }

  (:lowmemlarge) function set_fonts() {
    fontOffset = 2;
    fonts = [ 0, 1, 2, 3, 6, 8 ];
  }

  function onLayout(dc) { return true; }

  function compute(info) {
    return true;
  }

  function onUpdate(dc) {
    if (dc has :setAntiAlias){
      dc.setAntiAlias(true);
    }

    var width = dc.getWidth();
    var height = dc.getHeight();
  }
}