#if mobileC
package mobile;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class FlxVirtualPad extends FlxSpriteGroup
{
	public static inline var BUTTON_SIZE:Int = 140;
	public static inline var PADDING:Int = 20;
	public static inline var GAP:Int = 4;

	public var buttonA:FlxButton;
	public var buttonB:FlxButton;
	public var buttonC:FlxButton;
	public var buttonY:FlxButton;
	public var buttonX:FlxButton;
	public var buttonLeft:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonPause:FlxButton;

	public var dPad:FlxSpriteGroup;
	public var actions:FlxSpriteGroup;

	public function new(?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		super();
		scrollFactor.set();

		if (DPad == null)
			DPad = FULL;
		if (Action == null)
			Action = A_B_C;

		dPad = new FlxSpriteGroup();
		dPad.scrollFactor.set();

		actions = new FlxSpriteGroup();
		actions.scrollFactor.set();

		var s = BUTTON_SIZE;
		var g = GAP;

		switch (DPad)
		{
			case UP_DOWN:
				dPad.add(add(buttonUp = createButton(PADDING, FlxG.height - PADDING - (s * 2 + g), s, s, "up")));
				dPad.add(add(buttonDown = createButton(PADDING, FlxG.height - PADDING - s, s, s, "down")));
			case LEFT_RIGHT:
				dPad.add(add(buttonLeft = createButton(PADDING, FlxG.height - PADDING - s, s, s, "left")));
				dPad.add(add(buttonRight = createButton(PADDING + s + g, FlxG.height - PADDING - s, s, s, "right")));
			case UP_LEFT_RIGHT:
				dPad.add(add(buttonUp = createButton(PADDING + s + g, FlxG.height - PADDING - (s * 2 + g), s, s, "up")));
				dPad.add(add(buttonLeft = createButton(PADDING, FlxG.height - PADDING - s, s, s, "left")));
				dPad.add(add(buttonRight = createButton(PADDING + (s + g) * 2, FlxG.height - PADDING - s, s, s, "right")));
			case FULL:
				dPad.add(add(buttonUp = createButton(PADDING + s + g, FlxG.height - PADDING - (s * 2 + g), s, s, "up")));
				dPad.add(add(buttonLeft = createButton(PADDING, FlxG.height - PADDING - s, s, s, "left")));
				dPad.add(add(buttonRight = createButton(PADDING + (s + g) * 2, FlxG.height - PADDING - s, s, s, "right")));
				dPad.add(add(buttonDown = createButton(PADDING + s + g, FlxG.height - PADDING, s, s, "down")));
			case RIGHT_FULL:
				var baseX = FlxG.width - PADDING - (s * 3 + g * 2);
				dPad.add(add(buttonUp = createButton(baseX + s + g, FlxG.height - PADDING - (s * 2 + g), s, s, "up")));
				dPad.add(add(buttonLeft = createButton(baseX, FlxG.height - PADDING - s, s, s, "left")));
				dPad.add(add(buttonRight = createButton(baseX + (s + g) * 2, FlxG.height - PADDING - s, s, s, "right")));
				dPad.add(add(buttonDown = createButton(baseX + s + g, FlxG.height - PADDING, s, s, "down")));
			case NONE:
		}

		switch (Action)
		{
			case A:
				actions.add(add(buttonA = createButton(FlxG.width - PADDING - s, FlxG.height - PADDING - s, s, s, "a")));
			case A_B:
				actions.add(add(buttonA = createButton(FlxG.width - PADDING - s, FlxG.height - PADDING - s, s, s, "a")));
				actions.add(add(buttonB = createButton(FlxG.width - PADDING - (s + g) * 2, FlxG.height - PADDING - s, s, s, "b")));
			case A_B_C:
				actions.add(add(buttonC = createButton(FlxG.width - PADDING - s, FlxG.height - PADDING - s, s, s, "c")));
				actions.add(add(buttonB = createButton(FlxG.width - PADDING - (s + g) * 2, FlxG.height - PADDING - s, s, s, "b")));
				actions.add(add(buttonA = createButton(FlxG.width - PADDING - (s + g) * 3, FlxG.height - PADDING - s, s, s, "a")));
			case A_B_X_Y:
				actions.add(add(buttonY = createButton(FlxG.width - PADDING - (s + g) * 2, FlxG.height - PADDING - (s * 2 + g), s, s, "y")));
				actions.add(add(buttonX = createButton(FlxG.width - PADDING - s, FlxG.height - PADDING - (s * 2 + g), s, s, "x")));
				actions.add(add(buttonB = createButton(FlxG.width - PADDING - (s + g) * 2, FlxG.height - PADDING - s, s, s, "b")));
				actions.add(add(buttonA = createButton(FlxG.width - PADDING - s, FlxG.height - PADDING - s, s, s, "a")));
			case STOP:
				actions.add(add(buttonPause = createButton(FlxG.width - PADDING - s, PADDING, s, s, "pause")));
			case NONE:
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		dPad = FlxDestroyUtil.destroy(dPad);
		actions = FlxDestroyUtil.destroy(actions);

		dPad = null;
		actions = null;
		buttonA = null;
		buttonB = null;
		buttonC = null;
		buttonY = null;
		buttonX = null;
		buttonLeft = null;
		buttonUp = null;
		buttonDown = null;
		buttonRight = null;
		buttonPause = null;
	}

	function createButton(X:Float, Y:Float, Width:Int, Height:Int, ShapeName:String):FlxButton
	{
		var button = new FlxButton(X, Y);
		button.loadGraphic(buildGraphic(Width, Height, ShapeName));
		button.solid = false;
		button.immovable = true;
		button.scrollFactor.set();

		#if FLX_DEBUG
		button.ignoreDrawDebug = true;
		#end

		button.onDown.callback = function()
		{
			FlxTween.num(1, 0.6, 0.075, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
		};

		button.onUp.callback = function()
		{
			FlxTween.num(button.alpha, 1, 0.1, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
		};

		button.onOut.callback = function()
		{
			FlxTween.num(button.alpha, 1, 0.2, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
		};

		return button;
	}

	function buildGraphic(width:Int, height:Int, shapeName:String):FlxGraphic
	{
		var bmp = new BitmapData(width, height, true, 0x00000000);
		var base = new Shape();

		base.graphics.beginFill(0xffffff, 0.3);
		base.graphics.drawEllipse(0, 0, width, height);
		base.graphics.endFill();
		bmp.draw(base);

		switch (shapeName)
		{
			case "up", "down", "left", "right":
				drawArrow(bmp, width, height, getArrowAngle(shapeName));
			case "pause":
				drawPause(bmp, width, height);
			default:
				drawLabel(bmp, width, height, shapeName);
		}

		return FlxGraphic.fromBitmapData(bmp);
	}

	function getArrowAngle(direction:String):Float
	{
		return switch (direction)
		{
			case "up": 0;
			case "right": 90;
			case "down": 180;
			case "left": 270;
			default: 0;
		}
	}

	function drawArrow(bmp:BitmapData, width:Int, height:Int, angle:Float):Void
	{
		var arrow = new Shape();
		arrow.graphics.beginFill(0xffffff, 0.9);
		arrow.graphics.moveTo(-width * 0.2, height * 0.18);
		arrow.graphics.lineTo(width * 0.2, height * 0.18);
		arrow.graphics.lineTo(0, -height * 0.18);
		arrow.graphics.lineTo(-width * 0.2, height * 0.18);
		arrow.graphics.endFill();

		var matrix = new Matrix();
		matrix.rotate(angle * Math.PI / 180);
		matrix.translate(width / 2, height / 2);
		bmp.draw(arrow, matrix);
	}

	function drawPause(bmp:BitmapData, width:Int, height:Int):Void
	{
		var bars = new Shape();
		bars.graphics.beginFill(0xffffff, 0.9);
		bars.graphics.drawRect(width * 0.32, height * 0.28, width * 0.12, height * 0.44);
		bars.graphics.drawRect(width * 0.56, height * 0.28, width * 0.12, height * 0.44);
		bars.graphics.endFill();
		bmp.draw(bars);
	}

	function drawLabel(bmp:BitmapData, width:Int, height:Int, letter:String):Void
	{
		var tf = new TextField();
		tf.selectable = false;
		tf.width = width;
		tf.height = height;

		var format = new TextFormat(null, Std.int(height * 0.4), 0xffffff, true);
		format.align = TextFormatAlign.CENTER;
		tf.defaultTextFormat = format;
		tf.text = letter.toUpperCase();
		tf.y = (height - tf.textHeight) / 2;

		bmp.draw(tf);
	}
}

enum FlxDPadMode
{
	NONE;
	UP_DOWN;
	LEFT_RIGHT;
	UP_LEFT_RIGHT;
	RIGHT_FULL;
	FULL;
}

enum FlxActionMode
{
	NONE;
	A;
	A_B;
	A_B_C;
	A_B_X_Y;
	STOP;
}
#end
