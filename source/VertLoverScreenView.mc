using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.SensorHistory;

class VertLoverScreenApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
    }
    function getInitialView() {
        return [ new VertLoverScreenView() ];
    }
}

class VertLoverScreenView extends Ui.DataField {

    hidden var mElevation, mAscent, mDescent;
    hidden var mElapsedTime;
    hidden var mHeartRate, mAvgHeartRate, mCadence, mTemp;
    hidden var mPace, mAvgPace;
    hidden var mSpeed, mAvgSpeed;
    hidden var mDistance, mDistancePartial;
    hidden var mGPSAccuracy;

    // Labels in layout
    hidden var mBackground;
    hidden var mClockLabel, mTimerLabel;

    hidden const DASHDASH = "--";
    hidden const DASHDASH_TIME = "--:--";
    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

    hidden var mIsMetricDistance, mIsMetricElevation, mIsCelsius;

    function initialize() {
        DataField.initialize();
        mHeartRate = DASHDASH;
        mAvgHeartRate = DASHDASH;
        mCadence = DASHDASH;
        mTemp = DASHDASH;
        mElapsedTime = "00:00";
        mPace = DASHDASH_TIME;
        mAvgPace = DASHDASH_TIME;
        mSpeed = "0.0";
        mAvgSpeed = "0.0";
        mElevation = "0";
        mAscent = "+0";
        mDescent = "0";
        mDistance = "100";
        mDistancePartial = ".00";
        mGPSAccuracy = 0;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));

        System.println("Screen size: " + dc.getWidth() + " x " + dc.getHeight());

        mBackground = View.findDrawableById("background");
        mClockLabel = View.findDrawableById("clock");
        mTimerLabel = View.findDrawableById("timer");

        // System settings cache
        var settings = System.getDeviceSettings();
        mIsMetricDistance = settings.distanceUnits == System.UNIT_METRIC;
        mIsMetricElevation = settings.elevationUnits == System.UNIT_METRIC;
        mIsCelsius = settings.temperatureUnits == System.UNIT_METRIC;

        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        if (info == null) {
            return;
        }

        if (info has :currentHeartRate && info.currentHeartRate != null) {
            mHeartRate = info.currentHeartRate;
        }
        if (info has :averageHeartRate && info.averageHeartRate != null) {
            mAvgHeartRate = info.averageHeartRate;
        }
        if (info.currentCadence != null) {
            mCadence = info.currentCadence.format("%d");
        }
        // If the user prefers showing temperature in place of cadence, get the internal
        // device temperature from the SensorHistory class
        if (Application.Properties.getValue("tempNotCadence") &&
            Toybox has :SensorHistory && Toybox.SensorHistory has :getTemperatureHistory) {
            var it = SensorHistory.getTemperatureHistory({});
            var latest = null;
            if (it != null) {
                latest = it.next();
            }
            if (latest != null) {
                var t = latest.data.toDouble();
                mTemp = mIsCelsius ? t.format("%.1f") : (t * 9/5.0 + 32).format("%.1f");
            }
        }
        if (info.timerTime != null) {
            var seconds = ((info.timerTime / 1000).toLong() % 60).format("%02d");
            var minutes = ((info.timerTime / 60000).toLong() % 60).format("%02d");
            var hours = (info.timerTime / 3600000).format("%d");
            mElapsedTime = hours + ":" + minutes + ":" + seconds;
        }
        var hscale = mIsMetricDistance ? 1000 : 1609.34;
        if (info.elapsedDistance != null) {
            mDistance = (info.elapsedDistance / hscale).format("%.2f");
            var distLen = mDistance.length();
            mDistancePartial = mDistance.substring(distLen - 3, distLen);
            mDistance = mDistance.substring(0, distLen - 3);
        }
        var speedFactor = mIsMetricDistance ? 3.6 : 2.23694;
         if (info.currentSpeed != null) {
             mPace = getPaceString(info.currentSpeed);
             mSpeed = (info.currentSpeed * speedFactor).format("%.1f");
        }
        if (info.averageSpeed != null) {
            mAvgPace = getPaceString(info.averageSpeed);
            mAvgSpeed = (info.averageSpeed * speedFactor).format("%.1f");
        }

        var vscale = mIsMetricElevation ? 1 : 3.28084;
        var vunit = mIsMetricElevation ? "m" : "'";
        if (info.altitude != null) {
            mElevation = (info.altitude * vscale).format("%d") + vunit;
        }
        if (info.totalAscent != null) {
            mAscent = "+" + (info.totalAscent * vscale).format("%d");
        }
        if (info.totalDescent != null) {
             mDescent = (info.totalDescent * vscale).format("%d") + vunit;
         }

        if (info.currentLocationAccuracy != null) {
            mGPSAccuracy = info.currentLocationAccuracy / 4.0;
        }
    }

    function renderClockAndTime() {
        var time;
        var clock = System.getClockTime();
        if (System.getDeviceSettings().is24Hour) {
            time = clock.hour + ":" + clock.min.format("%.2d");
        } else {
            var hour = clock.hour == 0 || clock.hour == 12 ? 12 : clock.hour % 12;
            time = hour + ":" + clock.min.format("%.2d");
            time += clock.hour < 12 ? "a" : "p";
        }

        mClockLabel.setText(time.toString());
        mTimerLabel.setText(mElapsedTime.toString());
    }

    function getForegroundColor() {
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            return Gfx.COLOR_WHITE;
        }
        return Gfx.COLOR_BLACK;
    }

    // Displays the field values
    function onUpdate(dc) {
        // Set the background color
        mBackground.setColor(getBackgroundColor());

        // Clock time and current time
        renderClockAndTime();

        View.onUpdate(dc);
        dc.setColor(getForegroundColor(), Gfx.COLOR_TRANSPARENT);

        var centerX = dc.getWidth() / 2, margin = 5;


        // Heart rate and cadence or temp
        var cadenceOrTemp = Application.Properties.getValue("tempNotCadence") ? mTemp : mCadence;
        var hr = mHeartRate + "  " + mAvgHeartRate + "  " + cadenceOrTemp;
        dc.drawText(centerX, 80, Gfx.FONT_LARGE, hr, CENTER);

        // Elevation
        dc.drawText(centerX + 10, 113, Gfx.FONT_LARGE, " " + mElevation, LEFT);
        dc.drawText(centerX + 10, 143, Gfx.FONT_LARGE, "-" + mDescent, LEFT);
//        dc.drawText(centerX + 10, 143, Gfx.FONT_LARGE, "-", RIGHT);
        dc.drawText(centerX / 2 + 10, 128, Gfx.FONT_NUMBER_MEDIUM, mAscent, CENTER);

        // Pace or Speed
        if (Application.Properties.getValue("speedNotPace")) {
            var speedUnit = mIsMetricDistance ? "km/h" : "mph";
            dc.drawText(centerX, 177, Gfx.FONT_XTINY, speedUnit, CENTER);
            dc.drawText(centerX - 20, 177, Gfx.FONT_MEDIUM, mSpeed + " ", RIGHT);
            dc.drawText(centerX + 20, 177, Gfx.FONT_MEDIUM, " " + mAvgSpeed, LEFT);
        } else {
            var distUnit = mIsMetricDistance ? "km" : "mi";
            dc.drawText(centerX, 177, Gfx.FONT_XTINY, "/" + distUnit, CENTER);
            dc.drawText(centerX - 20, 177, Gfx.FONT_MEDIUM, mPace, RIGHT);
            dc.drawText(centerX + 20, 177, Gfx.FONT_MEDIUM, mAvgPace, LEFT);
        }

        // Distance
        var distFont = mDistance.length() > 4 ? Gfx.FONT_NUMBER_MILD : Gfx.FONT_NUMBER_MEDIUM;
        var partFont = Gfx.FONT_NUMBER_MILD;
        var distY = dc.getHeight() - dc.getFontHeight(distFont) / 2;
        var distWidth = dc.getTextWidthInPixels(mDistance, distFont);
        var partDistX = centerX + distWidth / 2;
        var partDistY = distY - dc.getFontHeight(partFont);
        dc.drawText(centerX, distY, distFont, mDistance, CENTER);
        dc.drawText(partDistX, partDistY, partFont, mDistancePartial, Gfx.TEXT_JUSTIFY_LEFT);

        // Battery and GPS bars
        View.findDrawableById("batterybar").setPercent(System.getSystemStats().battery / 100.0);
        View.findDrawableById("gpsbar").setPercent(mGPSAccuracy);
    }

    function getPaceString(speed) {
        var pscale = mIsMetricDistance ? 16.6667 : 26.8224;
        if (speed < 0.2) {
            return DASHDASH_TIME;
        }
        var minutes = pscale / speed;
        var seconds = (minutes - minutes.toLong()) * 60;
        return minutes.format("%d") + ":" + seconds.format("%02d");
    }


}

class HeartRateDisplay extends Ui.Drawable {

}

class ProgressArcBar extends Ui.Drawable {

    hidden var color, borderColor, thickness, clockwise, percentage;

    function initialize(params) {
        Drawable.initialize(params);

        color = params.get(:color);
        borderColor = params.get(:borderColor);
        clockwise = params.get(:clockwise);
        thickness = params.get(:thickness);
        percentage = 0.0;
    }

    function clamp(value, max, min) {
        if (value > max) {
            return max;
        }
        else if (value < min) {
            return min;
        }
        return value;
    }

    function setForegroundColor(color) {
        borderColor = color;
    }

    function setPercent(value) {
        percentage = clamp(value, 1.0, 0.0);
    }

    function draw(dc) {
        dc.setColor(color, color);
        if (percentage < .1) {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
        }
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var scale = clockwise ? -1 : 1;
        var start = 180, end = 180 + scale * (10 + 170 * percentage);
        for (var i = 1; i < thickness; i++) {
            dc.drawArc(x, y, x - i, clockwise, start, end);
        }
        dc.setColor(borderColor, borderColor);
        dc.drawArc(x, y, x - thickness, clockwise, start, end);
        dc.drawArc(x, y, x, clockwise, start, end);
    }
}

class Background extends Ui.Drawable {

    hidden var mColor;

    function initialize() {
        Drawable.initialize( { :identifier => "background" } );
    }

    function setColor(color) {
        mColor = color;
    }

    function draw(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, mColor);
        dc.clear();
    }
}
