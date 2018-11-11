using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;

class VertLoverScreenApp extends App.AppBase {
    function getInitialView() {
        return [ new VertLoverScreenView() ];
    }
}

class VertLoverScreenView extends Ui.DataField {

    hidden var mElevation, mAscent, mDescent;
    hidden var mElapsedTime;
    hidden var mHeartRate, mAvgHeartRate, mCadence;
    hidden var mPace, mAvgPace;
    hidden var mDistance;
    hidden var mDistanceUnit;
    hidden var mGPSAccuracy;

	hidden const DASHDASH = "--";
	hidden const DASHDASH_TIME = "--:--";
    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

    function initialize() {
        DataField.initialize();
        mHeartRate = DASHDASH;
        mAvgHeartRate = DASHDASH;
        mCadence = DASHDASH;
        mElapsedTime = "00:00";
        mPace = DASHDASH_TIME;
        mAvgPace = DASHDASH_TIME;
        mElevation = "0";
        mAscent = "+0";
        mDescent = "0";
        mDistance = "0.00";
        mDistanceUnit = "km";
        mGPSAccuracy = 0;
    }
    
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));
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
        if (info.timerTime != null) {
        	var seconds = ((info.timerTime / 1000).toLong() % 60).format("%02d");
        	var minutes = ((info.timerTime / 60000).toLong() % 60).format("%02d");
        	var hours = (info.timerTime / 3600000).format("%d");
        	mElapsedTime = hours + ":" + minutes + ":" + seconds;
        }
        var hscale = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC ? 1000 : 1609.34;
        mDistanceUnit = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC ? "km" : "mi";
        if (info.elapsedDistance != null) {
        	mDistance = (info.elapsedDistance / hscale).format("%.2f");
        }
 
 		if (info.currentSpeed != null) {
 			mPace = getPaceString(info.currentSpeed);
        }
        if (info.averageSpeed != null) {
        	mAvgPace = getPaceString(info.averageSpeed);
        }
        
        var vscale = System.getDeviceSettings().elevationUnits == System.UNIT_METRIC ? 1 : 3.28084;
        var vunit = System.getDeviceSettings().elevationUnits == System.UNIT_METRIC ? "m" : "'";
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

    // Displays the field values
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        var foreground = getBackgroundColor() == Gfx.COLOR_BLACK ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        
        // Battery and GPS bars
        View.findDrawableById("batterybar").setForegroundColor(foreground);
        View.findDrawableById("batterybar").setPercent(System.getSystemStats().battery / 100.0);
        View.findDrawableById("gpsbar").setForegroundColor(foreground);
        View.findDrawableById("gpsbar").setPercent(mGPSAccuracy);
		View.findDrawableById("skeleton_lines").setColor(foreground);
	
        View.onUpdate(dc);
        
		// The current time
		var time;
		var clock = System.getClockTime();
		if (System.getDeviceSettings().is24Hour) {
			time = clock.hour + ":" + clock.min.format("%.2d");
		} else {
			var hour = clock.hour == 0 || clock.hour == 12 ? 12 : clock.hour % 12;
			time = hour + ":" + clock.min.format("%.2d");
			time += clock.hour < 12 ? "a" : "p";
		}
		dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
		dc.drawText(dc.getWidth() / 2, 18, Gfx.FONT_SYSTEM_TINY, time, CENTER);
		
		// Elapsed time
		dc.drawText(dc.getWidth() / 2, 47, Gfx.FONT_SMALL, mElapsedTime, CENTER);
		
		// Heart rate and cadence
		var hr = mHeartRate + "  " + mAvgHeartRate + "  " + mCadence;
		dc.drawText(dc.getWidth() / 2, 80, Gfx.FONT_LARGE, hr, CENTER);
		
		// Elevation
		dc.drawText(dc.getWidth() / 2 + 10, 113, Gfx.FONT_LARGE, mElevation, LEFT);
		dc.drawText(dc.getWidth() / 2 + 10, 143, Gfx.FONT_LARGE, mDescent, LEFT);
		dc.drawText(dc.getWidth() / 2 + 10, 143, Gfx.FONT_LARGE, "-", RIGHT);
		dc.drawText(dc.getWidth() / 4 + 10, 128, Gfx.FONT_NUMBER_MEDIUM, mAscent, CENTER);
		
		// Pace
		dc.drawText(dc.getWidth() / 2, 177, Gfx.FONT_XTINY, "/" + mDistanceUnit, CENTER);
		dc.drawText(dc.getWidth() / 2 - 20, 177, Gfx.FONT_MEDIUM, mPace, RIGHT);
		dc.drawText(dc.getWidth() / 2 + 20, 177, Gfx.FONT_MEDIUM, mAvgPace, LEFT);
		
		// Distance
		var distanceFont = mDistance.length() > 4 ? Gfx.FONT_NUMBER_MILD : Gfx.FONT_NUMBER_MEDIUM;
		dc.drawText(dc.getWidth() / 2, 210, distanceFont, mDistance, CENTER);
    }
    
	function getPaceString(speed) {
	  	var pscale = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC ? 16.6667 : 26.8224;
	  	if (speed < 0.2) {
	  		return DASHDASH_TIME;
	  	}
	 	var minutes = pscale / speed;
	 	var seconds = (minutes - minutes.toLong()) * 60; 
	    return minutes.format("%d") + ":" + seconds.format("%02d");
	}


}

class SkeletonGrid extends Ui.Drawable {
	hidden var mPoints, mColor;
	
	function initialize(params) {
		Drawable.initialize(params);
		mPoints = params.get(:points);
		mColor = Gfx.COLOR_BLACK;
	}
	
	function setColor(color) {
		mColor = color;
	}
	
	function draw(dc) {
		dc.setColor(mColor, mColor);
		for (var i = 0; i < mPoints.size(); i++) {
			dc.drawRectangle(0, mPoints[i], dc.getWidth(), 1);
		}
	}
}

class ProgressArcBar extends Ui.Drawable {

    hidden var color, thickness, clockwise, percentage;
    hidden var foregroundColor;

    function initialize(params) {
        Drawable.initialize(params);

        color = params.get(:color);
        clockwise = params.get(:clockwise);
        thickness = params.get(:thickness);
        percentage = 0.0;
        foregroundColor = Gfx.COLOR_BLACK;
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
    	foregroundColor = color;
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
        dc.setColor(foregroundColor, foregroundColor);
        dc.drawArc(x, y, x - thickness, clockwise, start, end);
        dc.drawArc(x, y, x, clockwise, start, end);
    }
}

class Background extends Ui.Drawable {

    hidden var mColor;

    function initialize() {
        Drawable.initialize( { :identifier => "Background" } );
    }

    function setColor(color) {
        mColor = color;
    }

    function draw(dc) {
        dc.setColor(Gfx.COLOR_TRANSPARENT, mColor);
        dc.clear();
    }
}
