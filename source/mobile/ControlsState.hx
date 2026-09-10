#if mobileC
package mobile;

import flixel.FlxG;
import mobile.FlxVirtualPad;
import mobile.Hitbox;

class ControlsState extends MusicBeatSubstate
{
	var _hb:Hitbox;
	var _exitPad:FlxVirtualPad;

	public function new()
	{
		super();

		_hb = new Hitbox(FlxG.width);
		add(_hb);

		_exitPad = new FlxVirtualPad(NONE, B);
		_exitPad.alpha = 0.75;
		add(_exitPad);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (_exitPad.buttonB.justReleased #if android || FlxG.android.justReleased.BACK #end)
			close();
	}

	override function destroy()
	{
		super.destroy();

		_hb = null;
		_exitPad = null;
	}
}
#end
