#if mobileC
package mobile;

import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Hitbox extends FlxSpriteGroup
{
	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;

	public var hintVisible(default, set):Bool;

	var hitboxHint:FlxSprite;
	var zoneWidth:Int;
	var buttons:Array<FlxButton> = [];
	var tweens:Map<FlxButton, FlxTween> = new Map();

	public function new(?screenWidth:Int, hintVisible:Bool = false)
	{
		super();

		zoneWidth = screenWidth != null ? Std.int(screenWidth / 4) : Std.int(FlxG.width / 4);

		hitboxHint = new FlxSprite(0, 0).loadGraphic('assets/shared/images/hitbox/hitbox_hint.png');
		hitboxHint.scrollFactor.set();
		add(hitboxHint);

		buttonLeft = createZone(zoneWidth * 0, "left");
		buttonDown = createZone(zoneWidth * 1, "down");
		buttonUp = createZone(zoneWidth * 2, "up");
		buttonRight = createZone(zoneWidth * 3, "right");

		buttons = [buttonLeft, buttonDown, buttonUp, buttonRight];

		for (button in buttons)
			add(button);

		this.hintVisible = hintVisible;
	}

	function set_hintVisible(value:Bool):Bool
	{
		hintVisible = value;
		if (hitboxHint != null)
			hitboxHint.alpha = value ? 0.2 : 0;
		return value;
	}

	function createZone(x:Float, frameName:String):FlxButton
	{
		var button = new FlxButton(x, 0);
		var frames = FlxAtlasFrames.fromSparrow('assets/shared/images/hitbox/hitbox.png', 'assets/shared/images/hitbox/hitbox.xml');
		var graphic:FlxGraphic = FlxGraphic.fromFrame(frames.getByName(frameName));

		button.loadGraphic(graphic);
		button.alpha = 0;
		button.scrollFactor.set();

		button.onDown.callback = () -> pressFeedback(button, 0.75, 0.075);
		button.onUp.callback = () -> pressFeedback(button, 0, 0.1);
		button.onOut.callback = () -> pressFeedback(button, 0, 0.2);

		return button;
	}

	function pressFeedback(button:FlxButton, target:Float, duration:Float)
	{
		var existing = tweens.get(button);
		if (existing != null)
			existing.cancel();

		tweens.set(button, FlxTween.num(button.alpha, target, duration, {ease: FlxEase.circInOut}, (a:Float) -> button.alpha = a));
	}

	override public function destroy():Void
	{
		for (tween in tweens)
			tween.cancel();
		tweens.clear();

		super.destroy();

		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
		hitboxHint = null;
		buttons = null;
	}
}
#end
