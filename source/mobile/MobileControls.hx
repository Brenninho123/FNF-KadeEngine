#if mobileC
package mobile;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import mobile.Hitbox;

class MobileControls extends FlxSpriteGroup
{
	public var _hitbox:Hitbox;

	public function new()
	{
		super();

		_hitbox = new Hitbox(FlxG.width);
		add(_hitbox);
	}

	override public function destroy():Void
	{
		super.destroy();

		_hitbox = null;
	}
}
#end
