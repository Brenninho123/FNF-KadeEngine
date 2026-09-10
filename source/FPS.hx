package;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.Event;
import openfl.system.Capabilities;

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
		system = Capabilities.os;

		selectable = false;
		mouseEnabled = false;
		multiline = true;
		autoSize = LEFT;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		text = "FPS: 0\nSystem: " + system;

		addEventListener(Event.ENTER_FRAME, update);
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
