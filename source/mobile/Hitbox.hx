#if mobileC
package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.geom.Matrix;

class Hitbox extends FlxSpriteGroup
{
    public var hitbox:FlxSpriteGroup;

    var sizex:Int = 320;
    var screensizey:Int = 720;

    public var buttonLeft:FlxButton;
    public var buttonDown:FlxButton;
    public var buttonUp:FlxButton;
    public var buttonRight:FlxButton;

    public function new(?widghtScreen:Int)
    {
        super();

        sizex = widghtScreen != null ? Std.int(widghtScreen / 4) : 320;
        screensizey = FlxG.height;

        hitbox = new FlxSpriteGroup();
        hitbox.scrollFactor.set();

        hitbox.add(add(buttonLeft = createHitbox(0, 180)));
        hitbox.add(add(buttonDown = createHitbox(sizex, 270)));
        hitbox.add(add(buttonUp = createHitbox(sizex * 2, 90)));
        hitbox.add(add(buttonRight = createHitbox(sizex * 3, 0)));
    }

    function buildGraphic(angle:Float):FlxGraphic
    {
        var bmp = new BitmapData(sizex, screensizey, true, 0x00000000);

        var bg = new Shape();
        bg.graphics.beginFill(0xffffff, 0.08);
        bg.graphics.drawRect(0, 0, sizex, screensizey);
        bg.graphics.endFill();
        bmp.draw(bg);

        var arrow = new Shape();
        arrow.graphics.beginFill(0xffffff, 0.6);
        arrow.graphics.moveTo(-30, 25);
        arrow.graphics.lineTo(30, 25);
        arrow.graphics.lineTo(0, -25);
        arrow.graphics.lineTo(-30, 25);
        arrow.graphics.endFill();

        var matrix = new Matrix();
        matrix.rotate(angle * Math.PI / 180);
        matrix.translate(sizex / 2, screensizey / 2);
        bmp.draw(arrow, matrix);

        return FlxGraphic.fromBitmapData(bmp);
    }

    function createHitbox(x:Float, angle:Float):FlxButton
    {
        var button = new FlxButton(x, 0);
        button.loadGraphic(buildGraphic(angle));
        button.alpha = 0;

        button.onDown.callback = function()
        {
            FlxTween.num(0, 0.75, 0.075, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
        };

        button.onUp.callback = function()
        {
            FlxTween.num(0.75, 0, 0.1, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
        };

        button.onOut.callback = function()
        {
            FlxTween.num(button.alpha, 0, 0.2, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
        };

        return button;
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
