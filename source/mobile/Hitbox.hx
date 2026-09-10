#if mobileC
package mobile;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Hitbox extends FlxSpriteGroup
{
	public var hitbox:FlxSpriteGroup;

	var sizex:Int = 320;
	var screensizey:Int = 720;

	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;

	static inline var ACCENT_HEIGHT:Float = 64;
	static inline var BASE_ALPHA:Float = 0.18;
	static inline var PRESS_ALPHA:Float = 0.6;

	public function new(?widghtScreen:Int)
	{
		super();

		sizex = widghtScreen != null ? Std.int(widghtScreen / 4) : 320;
		screensizey = Std.int(FlxG.height);

		hitbox = new FlxSpriteGroup();
		hitbox.scrollFactor.set();

		hitbox.add(add(buttonLeft = createhitbox(0, "left", 0xFFC24B99)));
		hitbox.add(add(buttonDown = createhitbox(sizex, "down", 0xFF00FFFF)));
		hitbox.add(add(buttonUp = createhitbox(sizex * 2, "up", 0xFF12FA05)));
		hitbox.add(add(buttonRight = createhitbox(sizex * 3, "right", 0xFFF9393F)));

		add(buildDividers());
	}

	function buildDividers():FlxSprite
	{
		var lines:FlxSprite = new FlxSprite(0, 0).makeGraphic(sizex * 4, screensizey, FlxColor.TRANSPARENT, true);
		lines.scrollFactor.set();
		lines.alpha = 0.25;

		var lineStyle = {thickness: 2.0, color: FlxColor.WHITE};

		for (i in 1...4)
		{
			FlxSpriteUtil.drawLine(lines, sizex * i, screensizey - ACCENT_HEIGHT - 6, sizex * i, screensizey, lineStyle);
		}

		return lines;
	}

	public function createhitbox(X:Float, direction:String, color:FlxColor):FlxButton
	{
		var button = new FlxButton(X, 0);

		var graphic:FlxSprite = new FlxSprite().makeGraphic(sizex, screensizey, FlxColor.TRANSPARENT, true);

		FlxSpriteUtil.drawRoundRect(graphic, 4, screensizey - ACCENT_HEIGHT, sizex - 8, ACCENT_HEIGHT - 8, 18, 18, color);

		drawDirectionGlyph(graphic, direction, color);

		button.loadGraphic(graphic.pixels);
		button.alpha = BASE_ALPHA;

		button.onDown.callback = function()
		{
			FlxTween.num(BASE_ALPHA, PRESS_ALPHA, 0.075, {ease: FlxEase.circInOut}, function(a:Float) button.alpha = a);
		};

		button.onUp.callback = function()
		{
			FlxTween.num(button.alpha, BASE_ALPHA, 0.1, {ease: FlxEase.circInOut}, function(a:Float) button.alpha = a);
		}

		button.onOut.callback = function()
		{
			FlxTween.num(button.alpha, BASE_ALPHA, 0.2, {ease: FlxEase.circInOut}, function(a:Float) button.alpha = a);
		}

		return button;
	}

	function drawDirectionGlyph(sprite:FlxSprite, direction:String, color:FlxColor):Void
	{
		var cx:Float = sizex / 2;
		var cy:Float = screensizey - (ACCENT_HEIGHT / 2);
		var size:Float = 16;

		var points:Array<FlxPoint> = switch (direction)
		{
			case "left":
				[FlxPoint.get(cx - size, cy), FlxPoint.get(cx + size, cy - size), FlxPoint.get(cx + size, cy + size)];
			case "right":
				[FlxPoint.get(cx + size, cy), FlxPoint.get(cx - size, cy - size), FlxPoint.get(cx - size, cy + size)];
			case "up":
				[FlxPoint.get(cx, cy - size), FlxPoint.get(cx - size, cy + size), FlxPoint.get(cx + size, cy + size)];
			case "down":
				[FlxPoint.get(cx, cy + size), FlxPoint.get(cx - size, cy - size), FlxPoint.get(cx + size, cy - size)];
			default:
				[];
		}

		if (points.length == 0)
			return;

		FlxSpriteUtil.drawPolygon(sprite, points, FlxColor.WHITE);
	}

	override public function destroy():Void
	{
		super.destroy();

		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
	}
}
#end
