using Toybox.WatchUi;
using Toybox.Attention;
using Toybox.UserProfile;
using Toybox.AntPlus;
using Toybox.System as Sys;

class RaceWithPowerView extends WatchUi.DataField {
  (:ciq32) hidden var alertCount = 0;
  (:ciq32) hidden var alertDelay;
  (:ciq32) hidden var alertTimer = 0;
  (:ciq32) hidden var alertDisplayed = false;
  (:ciq32) hidden var alertType;
  (:ciq32) hidden var enableAlerts;
  (:ciq32) hidden var maxAlerts;
  (:ciq32) hidden var showAlerts;
  hidden var alternateMetric = false;
  hidden var avgPace;
  hidden var avgPower;
  hidden var cadence = 0;
  hidden var correction = [0,0,0];
  hidden var correctLap;
  hidden var currentPower;
  hidden var currentPowerAverage;
  hidden var currentPowerRaw;
  hidden var currentSpeed;
  hidden var elapsedDistance;
  hidden var enableAlternate;
  hidden var etaPace = [0,0];
  hidden var etaPower = [0,0];
  hidden var fontOffset = 0;
  hidden var fonts;
  hidden var FTP;
  hidden var hr = 0;
  hidden var hrZones;
  hidden var idealPace = [0,0];
  hidden var idealPower = [0,0];
  hidden var idealPowerTarget = 0;
  hidden var lapDistance = 0;
  hidden var lapLength = 0;
  hidden var lapPace = 0;
  hidden var lapPower;
  hidden var lapStartDistance = 0;
  hidden var lapStartTime = 0;
  hidden var lapTime = 0;
  hidden var paused = true;
  hidden var powerAverage;
  hidden var remainingDistance;
  hidden var sensor;
  hidden var showColors;
  hidden var showEta;
  hidden var showLapData;
  hidden var showTime;
  hidden var targetDistance;
  hidden var targetElevation;
  hidden var targetHigh = 0;
  hidden var targetLow = 0;
  hidden var targetPace = 0;
  hidden var targetPower;
  hidden var targetTime;
  hidden var timer;
  hidden var totalAscent;
  hidden var useMetric;
  hidden var usePercentage;
  hidden var vibrate;
  hidden var weight;

  function initialize(strydsensor) {

    usePercentage = Utils.replaceNull(
        Application.getApp().getProperty("A"), false);
    FTP = Utils.replaceNull(Application.getApp().getProperty("B"), 330);

    vibrate =
        Utils.replaceNull(Application.getApp().getProperty("D"), true);
    powerAverage =
        Utils.replaceNull(Application.getApp().getProperty("E"), 3);
    showColors =
        Utils.replaceNull(Application.getApp().getProperty("F"), 1);

    targetPower =
        Utils.replaceNull(Application.getApp().getProperty("J"), 350);

    if(usePercentage){
      targetPower = ((targetPower / 100.0) * FTP);
    }

    if(usePercentage){
      targetHigh = ((((targetPower * 1.01) / FTP) * 100 ) + 0.5).toNumber();
      targetLow = ((((targetPower * 0.99) / FTP) * 100 ) + 0.5).toNumber();
    } else {
      targetHigh = ((targetPower * 1.01) + 0.5).toNumber();
      targetLow = ((targetPower * 0.99) + 0.5).toNumber();
    }

    targetDistance =
        Utils.replaceNull(Application.getApp().getProperty("K"), 5000);

    targetTime =
        Utils.replaceNull(Application.getApp().getProperty("L"), "1200");

    var index = targetTime.find(":");
    if (index != null){
      var a = targetTime.substring(0, index);
      var b = null;
      var c = null;
      var rem = targetTime.substring(index+1, targetTime.length());
      index = rem.find(":");
      if(index != null){
        b = rem.substring(0, index);
        c = rem.substring(index+1, rem.length());
        targetTime = a.toNumber() * 3600 + b.toNumber() * 60 + c.toNumber();
      }else{
        b = rem;
        targetTime = a.toNumber() * 60 + b.toNumber();
      }
    }else{
      targetTime = targetTime.toNumber();
    }

    showTime =
        Utils.replaceNull(Application.getApp().getProperty("Q"), false);

    showLapData =
        Utils.replaceNull(Application.getApp().getProperty("R"), false);

    showEta =
        Utils.replaceNull(Application.getApp().getProperty("S"), false);

    targetElevation =
        Utils.replaceNull(Application.getApp().getProperty("N"), 0);

    lapLength =
        Utils.replaceNull(Application.getApp().getProperty("O"), 1000);

    correctLap =
        Utils.replaceNull(Application.getApp().getProperty("P"), true);

    weight =
        Utils.replaceNull(Application.getApp().getProperty("M"), 100);

    useMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC
                    ? true
                    : false;

    enableAlternate =
        Utils.replaceNull(Application.getApp().getProperty("T"), false);

    targetPace = (targetDistance * 1.0) / (targetTime * 1.0);
    idealPowerTarget = ((1.04 * targetDistance) / (targetTime * 1.0)) * weight;

    set_fonts();
    set_extra_settings();
    
    DataField.initialize();
    
    hrZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
    currentPowerAverage = new[powerAverage];
    sensor = strydsensor;
  }

  function onTimerStart() { paused = false; }

  function onTimerStop() { paused = true; }

  function onTimerResume() { paused = false; }

  function onTimerPause() { paused = true; }

  function onTimerLap() {
    lapTime = 0;

    if(correctLap){
      if(correction[2] == 0){
        lapStartTime = timer;
        lapStartDistance = Activity.getActivityInfo().elapsedDistance;
        var delta = elapsedDistance.toNumber() % lapLength.toNumber();
        if(delta <= 0.10 * lapLength){
          correction[1] = correction[0];
          correction[0] = -1 * delta;
        }else if(delta >= 0.90 * lapLength){
          correction[1] = correction[0];
          correction[0] = lapLength - delta;
        }
      } else {
        correction[0] = correction[1];
      }
    } else {
      lapStartTime = timer;
      lapStartDistance = Activity.getActivityInfo().elapsedDistance;
    }

    lapPower = null;
    lapPace = null;
  }

  function onTimerReset() {
  }

  (:highmem) function set_fonts() {
    if (Utils.replaceNull(Application.getApp().getProperty("I"), true)) {
      fontOffset = -4;
      fonts = [
        WatchUi.loadResource(Rez.Fonts.A), WatchUi.loadResource(Rez.Fonts.B),
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

  (:ciq2)
  function set_extra_settings(){

  }

  (:ciq32)
  function set_extra_settings(){
    showAlerts =
        Utils.replaceNull(Application.getApp().getProperty("W"), true);
        
    alertDelay =
        Utils.replaceNull(Application.getApp().getProperty("X"), 15);

    maxAlerts =
        Utils.replaceNull(Application.getApp().getProperty("Y"), 3);

    alertType =
        Utils.replaceNull(Application.getApp().getProperty("Z"), 1);
  }

  function onLayout(dc) { return true; }

  function compute(info) {

    if(correction[2] > 0){
      correction[2] = correction[2] - 1;
    }

    if (info has :currentCadence) {
      cadence = info.currentCadence;
    }
    if (info has :currentHeartRate) {
      hr = info.currentHeartRate;
    }

    if (info has :currentPower) {
      currentPower = info.currentPower;
    } else if(sensor != null){
      currentPower = sensor.currentPower;
    }

    if (info has :currentSpeed) {
      currentSpeed = info.currentSpeed;
    }

    if (info has :totalAscent) {
      totalAscent = info.totalAscent == null ? 0 : info.totalAscent;
    }

    if (usePercentage && currentPower != null) {
      currentPower =
          ((currentPower / (FTP * 1.0)) * 100).toNumber();
    }

    if (paused != true) {
      if (info != null) {
        timer = info.elapsedTime / 1000;
        lapTime = timer - lapStartTime;

        if(info.elapsedDistance != null && timer != 0){
          lapDistance = (info.elapsedDistance - lapStartDistance) + correction[0];
          elapsedDistance = info.elapsedDistance;
          avgPace = (info.elapsedDistance + correction[0]) / (timer * 1.0);
        }

        if (currentPower != null) {
          for (var i = powerAverage - 1; i > 0; --i) {
            currentPowerAverage[i] = currentPowerAverage[i - 1];
          }

          currentPowerAverage[0] = currentPower;

          if (lapPower == null) {
            lapPower = currentPower;
          } else if (lapTime != 0) {
            lapPower = (((lapPower * (lapTime - 1)) + currentPower) / (lapTime * 1.0));
          }

          if (avgPower == null) {
            avgPower = currentPower;
          } else if (lapTime != 0) {
            avgPower = (((avgPower * (timer - 1)) + currentPower) / (timer * 1.0));
          }

          var tempAverage = 0;
          var entries = powerAverage;

          for (var i = 0; i < powerAverage; ++i) {
            if (currentPowerAverage[i] != null){
              tempAverage += currentPowerAverage[i];
            } else {
              entries -= 1;
            }
          }
          currentPower = ((tempAverage * 1.0 / entries * 1.0) + 0.5).toNumber();
        } else {
          currentPower = 0;
        }
      }
    }

    if(lapTime != 0 && lapDistance != 0){
      lapPace = ((lapDistance + correction[0]) * 1.0) / (lapTime * 1.0);
    }

    if(elapsedDistance != null && elapsedDistance > 0 && lapPace != 0 && lapPace != null){
      etaPace[0] = (((elapsedDistance + correction[0]) * 1.0) / avgPace).toNumber();
      etaPace[1] = ((targetDistance * 1.0 - (elapsedDistance + correction[0]) * 1.0) / lapPace).toNumber();
      idealPace[0] = (((elapsedDistance + correction[0]) * 1.0) / targetPace).toNumber();
      idealPace[1] = ((targetDistance * 1.0 - (elapsedDistance + correction[0]) * 1.0) / targetPace).toNumber();
    }
    if(elapsedDistance != null && elapsedDistance > 0 && lapPower != 0){
      var remElevation = targetElevation - totalAscent;
      var remDistance = targetDistance - (elapsedDistance + correction[0]);
      if (remElevation > 0 && remDistance > 0){
        remDistance = remDistance + (remElevation * 2);
      }

      var factor = 1.0;

      if(usePercentage){
        factor = FTP / 100.0;
      }

      // method from https://blog.stryd.com/2020/01/10/how-to-calculate-your-race-time-from-your-target-power/ + adding the elevation in
      etaPower[0] = ((1.04 * (targetDistance - remDistance) ) / ((avgPower * factor) / (weight * 1.0)) + 0.5).toNumber();
      etaPower[1] = ((1.04 * remDistance ) / ((lapPower * factor) / (weight * 1.0)) + 0.5).toNumber();
      idealPower[0] = ((1.04 * (targetDistance - remDistance) ) / ((idealPowerTarget * 1.0) / (weight * 1.0)) + 0.5).toNumber();
      idealPower[1] = ((1.04 * remDistance ) / ((idealPowerTarget * 1.0) / (weight * 1.0)) + 0.5).toNumber();
    }

    etaPace[1] = etaPace[1] < 0 ? 0 : etaPace[1];
    idealPace[1] = idealPace[1] < 0 ? 0 : idealPace[1];
    etaPower[1] = etaPower[1] < 0 ? 0 : etaPower[1];
    idealPower[1] = idealPower[1] < 0 ? 0 : idealPower[1];

    if(!showEta && timer != null){
      etaPower[1] = etaPower[1] + timer;
      etaPace[1] = etaPace[1] + timer;
    }

    if(timer != null && timer % 5 == 0){
      alternateMetric = !alternateMetric;
    }

    checkAlert();
    
    return true;
  }

  (:ciq2)
  function checkAlert(){}

  (:ciq32)
  function checkAlert(){

    var metric = currentPower;

    if(alertType == 2){
      metric = lapPower;
    } else if (alertType == 3){
      metric = avgPower;
    }

    if (timer != null && timer > alertDelay && WatchUi.DataField has
        :showAlert && showAlerts) {

      if ((metric != null && (targetLow != 0 && targetHigh != 0) &&
            (metric < targetLow || metric > targetHigh))) {
        if (alertDisplayed == false) {
          if (alertCount < maxAlerts) {
            if (Attention has :vibrate && vibrate) {
              Attention.vibrate([
                new Attention.VibeProfile(100, 300),
                new Attention.VibeProfile(0, 50),
                new Attention.VibeProfile(100, 300),
                new Attention.VibeProfile(0, 50),
                new Attention.VibeProfile(100, 300)
              ]);
            }

            WatchUi.DataField.showAlert(new RaceWithPowerAlertView(
                targetHigh, targetLow, metric,
                [ fonts[2], fonts[5] ]));
            alertDisplayed = true;
            alertTimer = timer;
            alertCount++;
          }
        } else {
          if ((timer - alertTimer) > alertDelay) {
            alertDisplayed = false;
          }
        }
      } else {
        alertCount = 0;
      }
    }
  }

  function onUpdate(dc) {
    if (dc has :setAntiAlias){
      dc.setAntiAlias(true);
    }

    dc.clear();

    var width = dc.getWidth();
    var height = dc.getHeight();

    var bgColor = getBackgroundColor();
    var fgColor = bgColor == 0x000000 ? 0xFFFFFF : 0x000000;

    var geometry = [
      width / 2, height / 2, 0.1 * height, 0.2 * height, 0.40 * height, 0.6 * height, 0.6675 * height, 0.80 * height, // horizontal
      0.25 * width, 0.33 * width, 0.66 * width, 0.75 * width, 0.3 * height
    ];

    drawMetric(dc,1,geometry[11],geometry[3],geometry[8],geometry[3],2,bgColor,fgColor);
    drawMetric(dc,4,geometry[11],geometry[4],geometry[8],geometry[3],2,bgColor,fgColor);
    if(showTime){
      drawMetric(dc,7,0,0,width,geometry[2],1,bgColor,fgColor);
      drawMetric(dc,5,0,geometry[2],geometry[0],geometry[2],0,bgColor,fgColor);
      drawMetric(dc,6,geometry[0],geometry[2],geometry[0],geometry[2],2,bgColor,fgColor);
    }else {
      drawMetric(dc,5,0,0,geometry[0],geometry[2],0,bgColor,fgColor);
      drawMetric(dc,6,geometry[0],0,geometry[0],geometry[2],2,bgColor,fgColor);
    }
    if(showLapData){
      drawMetric(dc,2,geometry[8],geometry[3],geometry[1],geometry[4],1,bgColor,fgColor);
      drawMetric(dc,8,0,geometry[5],geometry[9],geometry[3],0,bgColor,fgColor);
      drawMetric(dc,9,geometry[9],geometry[5],geometry[9],geometry[3],1,bgColor,fgColor);
      drawMetric(dc,10,geometry[10],geometry[5],geometry[9],geometry[3],2,bgColor,fgColor);
      drawMetric(dc,3,0,geometry[4],geometry[8],geometry[3],0,bgColor,fgColor);
      drawMetric(dc,0,0,geometry[3],geometry[8],geometry[3],0,bgColor,fgColor);
      drawMetric(dc,11,0,geometry[7],width,geometry[3],1,bgColor,fgColor);
    } else {
      drawMetric(dc,2,0,geometry[3],geometry[11],geometry[4],1,bgColor,fgColor);
      drawMetric(dc,11,0,geometry[5],width,geometry[4],1,bgColor,fgColor);
      drawMetric(dc,0,0,geometry[7],width,geometry[3],1,-1,fgColor);
    }

    dc.setColor(fgColor,-1);
    // draw the lines
    if(showTime){
      dc.drawLine(0, geometry[2], width, geometry[2]);
    }
    dc.drawLine(0, geometry[3], width, geometry[3]);
    dc.drawLine(geometry[11], geometry[4], width, geometry[4]);
    dc.drawLine(0, geometry[5], width, geometry[5]);
    if(showTime){
      dc.drawLine(geometry[0], geometry[2], geometry[0], geometry[3]);
    } else {
      dc.drawLine(geometry[0], 0, geometry[0], geometry[3]);
    }
    dc.drawLine(geometry[11], geometry[3], geometry[11], geometry[4]);
    if(showLapData){
      dc.drawLine(0, geometry[4], geometry[8], geometry[4]);
      dc.drawLine(0, geometry[7], width, geometry[7]);
      dc.drawLine(geometry[9], geometry[5], geometry[9], geometry[7]);
      dc.drawLine(geometry[10], geometry[5], geometry[10], geometry[7]);
      dc.drawLine(geometry[8], geometry[3], geometry[8], geometry[4]);
    } else {
      
    }
  }

  function drawMetric(dc,type,x,y,width,height,align,bgColor,fgColor) {
    dc.setColor(bgColor,bgColor);
    dc.fillRectangle(x, y, width, height);
    dc.setColor(fgColor,-1);

    var label = "";
    var value = "";
    var textx = x + (width / 2);
    var labelx = textx;
    var labelFont = fonts[0];
    var textFont = fonts[3];
    var localOffset = 0;
    var labelOffset = -2;
    var showText = true;

    if(align == 0){
      textx = x + width - 3;
      labelx = textx;
    } else if(align == 2){
      textx = x + 3;
      labelx = textx;
    }

    if(type == 0) {
      textFont = fonts[1];
      var delta = etaPace[0] - idealPace[0];
      if(showLapData){
        localOffset = (height / 4) - fontOffset;
        if(delta<0){
          label = "AHEAD";
          value = "-"+Utils.format_duration(delta * -1);
        } else {
          label = "BEHIND";
          value = "+"+Utils.format_duration(delta);
        }
      } else{
        showText = false;
        labelFont = fonts[1];
        labelOffset = 5 - (2 * fontOffset);
        if(delta<0){
          label = "-"+Utils.format_duration(delta * -1);
        } else {
          label = "+"+Utils.format_duration(delta);
        }
      }
    } else if (type == 1){
      label = "HR";
      value = hr == null ? 0 : hr;
      if (hr != null) {
        if (showColors == 1) {
          if (hr > hrZones[4]) {
            dc.setColor(0xFF0000, -1);
          } else if (hr > hrZones[3]) {
            dc.setColor(0xFF5500, -1);
          } else if (hr > hrZones[2]) {
            dc.setColor(0x00AA00, -1);
          } else if (hr > hrZones[1]) {
            dc.setColor(0x0000FF, -1);
          } else {
            dc.setColor(0x555555, -1);
          }
          dc.fillRectangle(x, y, width, height);
          dc.setColor(0xFFFFFF, -1);
        } else if (showColors == 2) {
          if (hr > hrZones[4]) {
            dc.setColor(0xFF0000, -1);
          } else if (hr > hrZones[3]) {
            dc.setColor(0xFF5500, -1);
          } else if (hr > hrZones[2]) {
            dc.setColor(0x00AA00, -1);
          } else if (hr > hrZones[1]) {
            dc.setColor(0x0000FF, -1);
          } else {
            dc.setColor(0x555555, -1);
          }
        }
      }
    } else if (type == 2) {
      label = "CUR PWR "+powerAverage+"S";
      value = currentPower == null ? 0 : currentPower;
      textFont = fonts[5];
      localOffset = 5 + (fontOffset * 7);
      if(currentPower != null){
        if (showColors == 1) {
          if (currentPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (currentPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
          dc.fillRectangle(x, y, width, height);
          dc.setColor(0xFFFFFF, -1);
        } else if (showColors == 2) {
          if (currentPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (currentPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
        }
      }
    } else if (type == 3) {
      textFont = fonts[1];
      localOffset = (height / 4) - fontOffset;
      if(enableAlternate && alternateMetric){
        label = "PC DIFF";
        var delta = etaPace[1] - idealPace[1];
        if(delta<0){
          value = "-"+Utils.format_duration(delta * -1);
        } else {
          value = "+"+Utils.format_duration(delta);
        }
      } else {
        label = "PWR DIFF";
        var delta = etaPower[1] - idealPower[1];
        if(delta<0){
          value = "-"+Utils.format_duration(delta * -1);
        } else {
          value = "+"+Utils.format_duration(delta);
        }
      }
    } else if (type == 4) {
      label = "AVG PWR";
      value = avgPower == null ? 0 : avgPower.toNumber();
      if(avgPower != null){
        if (showColors == 1) {
          if (avgPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (avgPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
          dc.fillRectangle(x, y, width, height);
          dc.setColor(0xFFFFFF, -1);
        } else if (showColors == 2) {
          if (avgPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (avgPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
        }
      }
    } else if (type == 5) {
      var distance = Utils.format_distance((elapsedDistance == null ? 0 : elapsedDistance + correction[0]), useMetric);
      labelFont = fonts[showTime == true ? 1 : 2];
      labelOffset = showTime ? labelOffset + fontOffset : height / 1.5 + (2 * fontOffset);
      label = distance[0];
    } else if (type == 6) {
      labelFont = fonts[showTime ? 1 : 2];
      labelOffset = showTime ? labelOffset + fontOffset : height / 1.5 + (2 * fontOffset);
      label = Utils.format_duration(timer == null ? 0 : timer);
    } else if (type == 7) {
      labelFont = fonts[1];
      labelOffset = showTime ? labelOffset + fontOffset : height / 1.5 + (2 * fontOffset);
      var time = Sys.getClockTime();
      label = time.hour.format("%02d") + ":" + time.min.format("%02d");
    } else if (type == 8) {
      label = "LAP PACE";
      value = Utils.convert_speed_pace(lapPace, useMetric, false);
    } else if (type == 9) {
      label = "LAP PWR";
      value = lapPower == null ? 0 : lapPower.toNumber();
      if(lapPower != null){
        if (showColors == 1) {
          if (lapPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (lapPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
          dc.fillRectangle(x, y, width, height);
          dc.setColor(0xFFFFFF, -1);
        } else if (showColors == 2) {
          if (lapPower < targetLow) {
            dc.setColor(0x0000FF, -1);
          } else if (lapPower > targetHigh) {
            dc.setColor(0xAA0000, -1);
          } else {
            dc.setColor(0x00AA00, -1);
          }
        }
      }
    } else if (type == 10) {
      var distance = Utils.format_distance(lapDistance == null ? 0 : lapDistance, useMetric);
      label = "LAP DIST "+distance[1];
      value = distance[0];
    } else if (type == 11) {
      if(!showLapData){
        localOffset = 4;
        textFont = fonts[4];
      }
      if(enableAlternate && alternateMetric){
        label = showEta ? "ETA PACE" : "FINISH TIME PACE";
        value = Utils.format_duration(etaPace[1]);
      } else {
        label = showEta ? "ETA POWER" : "FINISH TIME POWER";
        value = Utils.format_duration(etaPower[1]);
      }
    }

    dc.drawText(labelx, y + labelOffset, labelFont, label, align);

    if(showText){
      dc.drawText(textx, y + (fontOffset * 5) + localOffset + 15, textFont, value, align);
    }
  }

}