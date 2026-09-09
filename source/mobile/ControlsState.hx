#if mobileC
package mobile;

import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUIButton;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import mobile.FlxVirtualPad;
import flixel.math.FlxPoint;
import haxe.Json;
import mobile.Hitbox;
import KadeEngineData;
#if lime
import lime.system.Clipboard;
#end

using StringTools;

class ControlsState extends MusicBeatSubstate
{
	var _pad:FlxVirtualPad;
	var _hb:Hitbox;

	var exitbutton:FlxUIButton;
	var exportbutton:FlxUIButton;
	var importbutton:FlxUIButton;

	var up_text:FlxText;
	var down_text:FlxText;
	var left_text:FlxText;
	var right_text:FlxText;

	var inputvari:FlxText;

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var controlitems:Array<String> = ['right control', 'left control', 'keyboard', 'custom', 'hitbox'];

	var curSelected:Int = 0;

	var buttonistouched:Bool = false;

	var bindbutton:FlxButton;

	var config:KadeEngineData;

	public function new()
	{
		super();

		config = new KadeEngineData();

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;

		curSelected = config.getcontrolmode();

		_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
		_pad.alpha = 0;

		_hb = new Hitbox(FlxG.width, false);

		inputvari = new FlxText(125, 50, 0, controlitems[0], 48);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		leftArrow = new FlxSprite(inputvari.x - 60, inputvari.y - 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');

		rightArrow = new FlxSprite(inputvari.x + inputvari.width + 10, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');

		up_text = new FlxText(200, 200, 0, "Button up x:" + _pad.buttonUp.x + " y:" + _pad.buttonUp.y, 24);
		down_text = new FlxText(200, 250, 0, "Button down x:" + _pad.buttonDown.x + " y:" + _pad.buttonDown.y, 24);
		left_text = new FlxText(200, 300, 0, "Button left x:" + _pad.buttonLeft.x + " y:" + _pad.buttonLeft.y, 24);
		right_text = new FlxText(200, 350, 0, "Button right x:" + _pad.buttonRight.x + " y:" + _pad.buttonRight.y, 24);

		exitbutton = new FlxUIButton(FlxG.width - 650, 25, "exit");
		exitbutton.resize(125, 50);
		exitbutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK, "center");

		var savebutton = new FlxUIButton((exitbutton.x + exitbutton.width + 25), 25, "exit and save", () -> {
			save();
			FlxG.switchState(new OptionsMenu());
		});
		savebutton.resize(250, 50);
		savebutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK, "center");

		exportbutton = new FlxUIButton(FlxG.width - 150, 25, "export", () -> savetoclipboard(_pad));
		exportbutton.resize(125, 50);
		exportbutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK, "center");

		importbutton = new FlxUIButton(exportbutton.x, 100, "import", () -> loadfromclipboard(_pad));
		importbutton.resize(125, 50);
		importbutton.setLabelFormat("VCR OSD Mono", 24, FlxColor.BLACK, "center");

		add(bg);

		add(exitbutton);
		add(savebutton);
		add(exportbutton);
		add(importbutton);

		add(_pad);
		add(_hb);

		add(inputvari);
		add(leftArrow);
		add(rightArrow);

		add(up_text);
		add(down_text);
		add(left_text);
		add(right_text);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (exitbutton.justReleased #if android || FlxG.android.justReleased.BACK #end)
			FlxG.switchState(new MainMenuState());

		for (touch in FlxG.touches.list)
		{
			arrowanimate(touch);

			if (touch.overlaps(leftArrow) && touch.justPressed || controls.LEFT_P)
				changeSelection(-1);
			else if (touch.overlaps(rightArrow) && touch.justPressed || controls.RIGHT_P)
				changeSelection(1);

			trackbutton(touch);
		}
	}

	function changeSelection(change:Int = 0, ?forceChange:Int)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = controlitems.length - 1;
		if (curSelected >= controlitems.length)
			curSelected = 0;

		if (forceChange != null)
			curSelected = forceChange;

		inputvari.text = controlitems[curSelected];

		if (forceChange != null && curSelected == 2)
		{
			_pad.visible = true;
			return;
		}

		switch curSelected
		{
			case 0:
				swapPad(RIGHT_FULL);
			case 1:
				swapPad(FULL);
			case 2:
				remove(_pad);
				remove(_hb);
			case 3:
				add(_pad);
				_pad.alpha = 0.75;
				loadcustom();
			case 4:
				remove(_pad);
				_pad.alpha = 0;
				add(_hb);
		}
	}

	function swapPad(layout:FlxDPadMode)
	{
		remove(_pad);
		_pad = new FlxVirtualPad(layout, NONE);
		_pad.alpha = 0.75;
		add(_pad);
	}

	function arrowanimate(touch:flixel.input.touch.FlxTouch)
	{
		if (touch.overlaps(leftArrow) && touch.pressed)
			leftArrow.animation.play('press');

		if (touch.overlaps(leftArrow) && touch.released)
			leftArrow.animation.play('idle');

		if (touch.overlaps(rightArrow) && touch.pressed)
			rightArrow.animation.play('press');

		if (touch.overlaps(rightArrow) && touch.released)
			rightArrow.animation.play('idle');
	}

	function trackbutton(touch:flixel.input.touch.FlxTouch)
	{
		if (buttonistouched)
		{
			if (bindbutton.justReleased && touch.justReleased)
			{
				bindbutton = null;
				buttonistouched = false;
			}
			else
			{
				movebutton(touch, bindbutton);
				setbuttontexts();
			}
		}
		else
		{
			if (_pad.buttonUp.justPressed)
			{
				if (curSelected != 3)
					changeSelection(0, 3);

				movebutton(touch, _pad.buttonUp);
			}

			if (_pad.buttonDown.justPressed)
			{
				if (curSelected != 3)
					changeSelection(0, 3);

				movebutton(touch, _pad.buttonDown);
			}

			if (_pad.buttonRight.justPressed)
			{
				if (curSelected != 3)
					changeSelection(0, 3);

				movebutton(touch, _pad.buttonRight);
			}

			if (_pad.buttonLeft.justPressed)
			{
				if (curSelected != 3)
					changeSelection(0, 3);

				movebutton(touch, _pad.buttonLeft);
			}
		}
	}

	function movebutton(touch:flixel.input.touch.FlxTouch, button:FlxButton)
	{
		button.x = touch.x - _pad.buttonUp.width / 2;
		button.y = touch.y - _pad.buttonUp.height / 2;
		bindbutton = button;
		buttonistouched = true;
	}

	function setbuttontexts()
	{
		up_text.text = "Button up x:" + _pad.buttonUp.x + " y:" + _pad.buttonUp.y;
		down_text.text = "Button down x:" + _pad.buttonDown.x + " y:" + _pad.buttonDown.y;
		left_text.text = "Button left x:" + _pad.buttonLeft.x + " y:" + _pad.buttonLeft.y;
		right_text.text = "Button right x:" + _pad.buttonRight.x + " y:" + _pad.buttonRight.y;
	}

	function save()
	{
		config.setcontrolmode(curSelected);

		if (curSelected == 3)
			savecustom();
	}

	function savecustom()
	{
		config.savecustom(_pad);
	}

	function loadcustom():Void
	{
		_pad = config.loadcustom(_pad);
	}

	function savetoclipboard(pad:FlxVirtualPad)
	{
		var json = {buttonsarray: []};
		var buttonsarray = new Array();

		for (buttons in pad)
			buttonsarray.push(FlxPoint.get(buttons.x, buttons.y));

		json.buttonsarray = buttonsarray;

		var data:String = Json.stringify(json);
		openfl.system.System.setClipboard(data.trim());
	}

	function loadfromclipboard(pad:FlxVirtualPad):Void
	{
		if (curSelected != 3)
			changeSelection(0, 3);

		var cbtext:String = Clipboard.text;

		if (!cbtext.endsWith("}"))
			return;

		var json = Json.parse(cbtext);
		var tempCount:Int = 0;

		for (buttons in pad)
		{
			buttons.x = json.buttonsarray[tempCount].x;
			buttons.y = json.buttonsarray[tempCount].y;
			tempCount++;
		}

		setbuttontexts();
	}

	override function destroy()
	{
		super.destroy();
	}
}
#end
