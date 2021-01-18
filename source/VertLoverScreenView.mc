using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.SensorHistory;
using Toybox.UserProfile as UProf;

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
    hidden var mElapsedTime, mTemp;
    hidden var mPace, mAvgPace;
    hidden var mSpeed, mAvgSpeed;
    hidden var mDistance, mDistancePartial;
    hidden var mGPSAccuracy;

    // Labels in layout
    hidden var mBackground;
    hidden var mClockLabel, mTimerLabel, mTempLabel;
    hidden var mAscentLabel, mDescentLabel, mElevationLabel;
    hidden var mCurPaceLabel, mAvgPaceLabel, mPaceUnitLabel;
    hidden var mDistLabel;

    hidden var mBatteryBar, mGPSBar;
    hidden var mCurHRField, mAvgHRField;

    hidden var mLastFgColor;
    hidden var mTextFields;

    hidden const DASHDASH_TIME = "--:--";
    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

    hidden var mIsMetricDistance, mIsMetricElevation, mIsCelsius;
    hidden var mSpeedNotPace;

    function initialize() {
        DataField.initialize();
        mTemp = "--";
        mElapsedTime = "00:00";
        mPace = DASHDASH_TIME;
        mAvgPace = DASHDASH_TIME;
        mSpeed = "0.0";
        mAvgSpeed = "0.0";
        mElevation = "0";
        mAscent = "0";
        mDescent = "0";
        mDistance = "0.00";
        mGPSAccuracy = 0;
    }

    // Called any time the draw context is changed.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));

        mBackground = View.findDrawableById("background");
        mClockLabel = View.findDrawableById("clock");
        mTimerLabel = View.findDrawableById("timer");
        mTempLabel = View.findDrawableById("temp");
        mAscentLabel = View.findDrawableById("ascent");
        mDescentLabel = View.findDrawableById("descent");
        mElevationLabel = View.findDrawableById("elevation");
        mCurPaceLabel = View.findDrawableById("curPace");
        mAvgPaceLabel = View.findDrawableById("avgPace");
        mPaceUnitLabel = View.findDrawableById("paceUnit");
        mDistLabel = View.findDrawableById("distance");

        mTextFields = [mClockLabel, mTimerLabel, mTempLabel,
            mAscentLabel, mDescentLabel, mElevationLabel, mCurPaceLabel,
            mAvgPaceLabel, mPaceUnitLabel, mDistLabel];
        mLastFgColor = null;

        mCurHRField = View.findDrawableById("curHR");
        mAvgHRField = View.findDrawableById("avgHR");

        mBatteryBar = View.findDrawableById("batterybar");
        mGPSBar = View.findDrawableById("gpsbar");

        // System settings cache
        var settings = System.getDeviceSettings();
        mIsMetricDistance = settings.distanceUnits == System.UNIT_METRIC;
        mIsMetricElevation = settings.elevationUnits == System.UNIT_METRIC;
        mIsCelsius = settings.temperatureUnits == System.UNIT_METRIC;

        // Settings
        mSpeedNotPace = Application.Properties.getValue("speedNotPace");

        return true;
    }

    // The given info object contains all the current workout information.
    // Calculates all the field values to be displayed.  Note that
    // compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        if (info == null) {
            return;
        }

        if (info has :currentHeartRate) {
            mCurHRField.setValue(info.currentHeartRate);
        }
        if (info has :averageHeartRate) {
            mAvgHRField.setValue(info.averageHeartRate);
        }

        if (Toybox has :SensorHistory && Toybox.SensorHistory has :getTemperatureHistory) {
            var it = SensorHistory.getTemperatureHistory({});
            var latest = null;
            if (it != null) {
                latest = it.next();
            }
            if (latest != null) {
                var t = latest.data.toDouble();
                mTemp = mIsCelsius ? t.format("%d") : (t * 9/5.0 + 32).format("%d");
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
        if (info.altitude != null) {
            mElevation = (info.altitude * vscale).format("%d");
        }
        if (info.totalAscent != null) {
            mAscent = (info.totalAscent * vscale).format("%d");
        }
        if (info.totalDescent != null) {
            mDescent = (info.totalDescent * vscale).format("%d");
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

        mTempLabel.setText(mTemp + "°" + (mIsCelsius ? "C" : "F"));

        // Battery and GPS bars
        mBatteryBar.setPercent(System.getSystemStats().battery / 100.0);
        mGPSBar.setPercent(mGPSAccuracy);

        // Elevation
        var wide = (dc.getWidth() > 240 && mAscent.length() > 4);
        var ascentFont = wide ? Gfx.FONT_NUMBER_MEDIUM : Gfx.FONT_NUMBER_HOT;
        mAscentLabel.setFont(ascentFont);
        mAscentLabel.setText((mAscent.length() < 5 ? "+" : "") + mAscent);
        mDescentLabel.setText("-" + mDescent);
        mElevationLabel.setText(mElevation);

        // Pace or Speed
        if (mSpeedNotPace) {
            mPaceUnitLabel.setText(mIsMetricDistance ? "km/h" : "mph");
            mCurPaceLabel.setText(mSpeed);
            mAvgPaceLabel.setText(mAvgSpeed);
        } else {
            mPaceUnitLabel.setText(mIsMetricDistance ? "/km" : "/mi");
            mCurPaceLabel.setText(mPace);
            mAvgPaceLabel.setText(mAvgPace);
        }

        // Distance
        mDistLabel.setText(mDistance);
        if (mDistance.length() > 5) {
            mDistLabel.setFont(Gfx.FONT_LARGE);
        }

        // Update the color of the fields the background color changes
        var color = getForegroundColor();
        if (color != mLastFgColor) {
            for (var i = 0; i < mTextFields.size(); ++i) {
                mTextFields[i].setColor(color);
            }
            mLastFgColor = color;
        }

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        View.onUpdate(dc);
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
    hidden var mZones;
    hidden var mFont, mMargin, mRadius;
    hidden var mAlign;
    hidden var mValue;
    hidden var mHeight;

    function initialize(params) {
        Drawable.initialize(params);
        mZones = UProf.getHeartRateZones(UProf.HR_ZONE_SPORT_GENERIC);
        mFont = params.get(:font);
        mMargin = params has :margin ? params.get(:margin) : 5;
        mRadius = params has :radius ? params.get(:radius) : 5;
        mHeight = Gfx.getFontHeight(mFont) + mMargin;
        mAlign = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
    }

    function setValue(value) {
        mValue = value;
    }

    function draw(dc) {
        var disp = mValue != null ? mValue : "--";

        var color;
        var fgColor = Gfx.COLOR_WHITE;
        if (mValue == null) {
            color = Gfx.COLOR_DK_GRAY;
        } else if (mValue < mZones[0]) {
            color = Gfx.COLOR_DK_GRAY;
        } else if (mValue < mZones[1]) {
            color = Gfx.COLOR_LT_GRAY;
            fgColor = Gfx.COLOR_BLACK;
        } else if (mValue < mZones[2]) {
            color = Gfx.COLOR_DK_BLUE;
        } else if (mValue < mZones[3]) {
            color = Gfx.COLOR_DK_GREEN;
        } else if (mValue < mZones[4]) {
            color = Gfx.COLOR_ORANGE;
            fgColor = Gfx.COLOR_BLACK;
        } else {
            color = Gfx.COLOR_DK_RED;
        }

        dc.setColor(color, color);
        width = dc.getTextWidthInPixels("999", mFont) + mMargin;
        dc.fillRoundedRectangle(locX - width / 2, locY - mHeight / 2,
                                width, mHeight, mRadius);
        dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(locX, locY, mFont, disp, mAlign);
    }
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

    function initialize(params) {
        Drawable.initialize(params);
    }

    function setColor(color) {
        mColor = color;
    }

    function draw(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, mColor);
        dc.clear();
    }
}
