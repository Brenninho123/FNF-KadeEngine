package;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.Event;

#if android
import extension.androidtools.device.Device;
#end

class FPS extends TextField
{
	public var currentFPS(default, null):Int;
	public var system(default, null):String;

	var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 5, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		times = [];
		system = detectSystem();

		selectable = false;
		mouseEnabled = false;
		multiline = true;
		autoSize = LEFT;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		text = "FPS: 0\nSystem: " + system;

		addEventListener(Event.ENTER_FRAME, update);
	}

	function detectSystem():String
	{
		#if android
		return "Android " + Device.getVersionRelease();
		#elseif ios
		return "iOS";
		#elseif html5
		return "HTML5";
		#elseif sys
		return Sys.systemName();
		#else
		return "Unknown";
		#end
	}

	function update(_:Event):Void
	{
		var now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);

		while (times[0] < now - 1000)
			times.shift();

		currentFPS = times.length;

		text = "FPS: " + currentFPS + "\nSystem: " + system;
	}
}
