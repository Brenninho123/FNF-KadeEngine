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

        var graphic = buildGraphic();

        hitbox.add(add(buttonLeft = createHitbox(0, graphic)));
        hitbox.add(add(buttonDown = createHitbox(sizex, graphic)));
        hitbox.add(add(buttonUp = createHitbox(sizex * 2, graphic)));
        hitbox.add(add(buttonRight = createHitbox(sizex * 3, graphic)));
    }

    function buildGraphic():FlxGraphic
    {
        var bmp = new BitmapData(sizex, screensizey, true, 0x00000000);

        var shape = new Shape();
        shape.graphics.beginFill(0xffffff, 1);
        shape.graphics.drawRect(0, 0, sizex, screensizey);
        shape.graphics.endFill();
        bmp.draw(shape);

        return FlxGraphic.fromBitmapData(bmp);
    }

    function createHitbox(x:Float, graphic:FlxGraphic):FlxButton
    {
        var button = new FlxButton(x, 0);
        button.loadGraphic(graphic);
        button.alpha = 0;

        button.onDown.callback = function()
        {
            FlxTween.num(0, 0.35, 0.075, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
        };

        button.onUp.callback = function()
        {
            FlxTween.num(0.35, 0, 0.1, {ease: FlxEase.circInOut}, function(a:Float) { button.alpha = a; });
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
