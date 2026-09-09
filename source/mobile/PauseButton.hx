#if mobileC
package mobile;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class PauseButton extends FlxSprite
{
	public var onPress:Void->Void;

	var pressed:Bool = false;
	var touchID:Int = -1;
	var scaleTween:FlxTween;

	public function new(x:Float = 0, y:Float = 0, ?onPress:Void->Void)
	{
		super(x, y);

		this.onPress = onPress;

		frames = FlxAtlasFrames.fromSparrow('assets/preload/images/pauseButton.png', 'assets/preload/images/pauseButton.xml');

		animation.addByPrefix('idle', 'pause00', 24, true);
		animation.play('idle');

		scrollFactor.set();
		antialiasing = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		for (touch in FlxG.touches.list)
		{
			if (!pressed && touch.justPressed && touch.overlaps(this))
			{
				pressed = true;
				touchID = touch.touchPointID;
				press();
			}
			else if (pressed && touch.touchPointID == touchID && touch.justReleased)
			{
				release();
			}
		}

		#if FLX_MOUSE
		if (!pressed && FlxG.mouse.justPressed && FlxG.mouse.overlaps(this))
		{
			pressed = true;
			press();
		}
		else if (pressed && touchID == -1 && FlxG.mouse.justReleased)
		{
			release();
		}
		#end
	}

	function press():Void
	{
		punch(0.85, 0.08);
	}

	function release():Void
	{
		pressed = false;
		touchID = -1;

		punch(1, 0.12);

		if (onPress != null)
			onPress();
	}

	function punch(target:Float, duration:Float):Void
	{
		if (scaleTween != null)
			scaleTween.cancel();

		scaleTween = FlxTween.tween(scale, {x: target, y: target}, duration, {ease: FlxEase.circOut});
	}

	override public function destroy():Void
	{
		if (scaleTween != null)
			scaleTween.cancel();

		super.destroy();
	}
}
#end
