import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
#if cpp
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import flixel.FlxSprite;
import hxlua.Lua;
import hxlua.LuaL;
import hxlua.Types;
import cpp.RawPointer;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;

class ModChartState
{
	public static var lua:RawPointer<Lua_State> = null;

	public static var luaSprites:Map<String, FlxSprite> = [];

	function callLua(func_name:String, args:Array<Dynamic>, ?type:String):Dynamic
	{
		Lua.getglobal(lua, func_name);

		for (arg in args)
			LuaHelper.pushDynamic(lua, arg);

		var result:Int = Lua.pcall(lua, args.length, 1, 0);

		if (result != 0)
		{
			var message:String = LuaHelper.readValue(lua, -1);
			Lua.pop(lua, 1);

			Application.current.window.alert("LUA ERROR:\n" + message, "Kade Engine Modcharts");
			lua = null;
			LoadingState.loadAndSwitchState(new MainMenuState());
			return null;
		}

		var value:Dynamic = LuaHelper.readValue(lua, -1);
		Lua.pop(lua, 1);

		return value == null ? null : convert(value, type);
	}

	private function convert(v:Any, type:String):Dynamic
	{
		if (Std.is(v, String) && type != null)
		{
			var v:String = v;

			if (type.substr(0, 5) == "array")
			{
				var array:Array<String> = v.split(",");

				if (type.substr(5) == "float")
					return [for (item in array) Std.parseFloat(item)];
				else if (type.substr(5) == "int")
					return [for (item in array) Std.parseInt(item)];
				else
					return array;
			}
			else if (type == "float")
				return Std.parseFloat(v);
			else if (type == "int")
				return Std.parseInt(v);
			else if (type == "bool")
				return v == "true";
			else
				return v;
		}

		return v;
	}

	public function setVar(var_name:String, object:Dynamic):Void
	{
		if (!LuaHelper.pushDynamic(lua, object))
			Lua.pushnil(lua);

		Lua.setglobal(lua, var_name);
	}

	public function getVar(var_name:String, type:String):Dynamic
	{
		Lua.getglobal(lua, var_name);

		var result:Dynamic = LuaHelper.readValue(lua, -1);
		Lua.pop(lua, 1);

		return result == null ? null : convert(result, type);
	}

	function getActorByName(id:String):Dynamic
	{
		switch (id)
		{
			case "boyfriend":
				@:privateAccess
				return PlayState.boyfriend;
			case "girlfriend":
				@:privateAccess
				return PlayState.gf;
			case "dad":
				@:privateAccess
				return PlayState.dad;
		}

		if (luaSprites.get(id) == null)
		{
			if (Std.parseInt(id) == null)
				return Reflect.getProperty(PlayState.instance, id);

			return PlayState.strumLineNotes.members[Std.parseInt(id)];
		}

		return luaSprites.get(id);
	}

	function getPropertyByName(id:String):Dynamic
	{
		return Reflect.field(PlayState.instance, id);
	}

	function changeDadCharacter(id:String):Void
	{
		var olddadx = PlayState.dad.x;
		var olddady = PlayState.dad.y;
		PlayState.instance.removeObject(PlayState.dad);
		PlayState.dad = new Character(olddadx, olddady, id);
		PlayState.instance.addObject(PlayState.dad);
		PlayState.instance.iconP2.animation.play(id);
	}

	function changeBoyfriendCharacter(id:String):Void
	{
		var oldboyfriendx = PlayState.boyfriend.x;
		var oldboyfriendy = PlayState.boyfriend.y;
		PlayState.instance.removeObject(PlayState.boyfriend);
		PlayState.boyfriend = new Boyfriend(oldboyfriendx, oldboyfriendy, id);
		PlayState.instance.addObject(PlayState.boyfriend);
		PlayState.instance.iconP2.animation.play(id);
	}

	function makeLuaSprite(spritePath:String, toBeCalled:String, drawBehind:Bool):String
	{
		#if sys
		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();

		switch (songLowercase)
		{
			case "dad-battle": songLowercase = "dadbattle";
			case "philly-nice": songLowercase = "philly";
		}

		var data:BitmapData = BitmapData.fromFile(Sys.getCwd() + "assets/data/" + songLowercase + "/" + spritePath + ".png");

		var sprite:FlxSprite = new FlxSprite(0, 0);
		var imgWidth:Float = FlxG.width / data.width;
		var imgHeight:Float = FlxG.height / data.height;
		var scale:Float = imgWidth <= imgHeight ? imgWidth : imgHeight;

		if (scale > 1)
			scale = 1;

		sprite.makeGraphic(Std.int(data.width * scale), Std.int(data.width * scale), FlxColor.TRANSPARENT);

		var data2:BitmapData = sprite.pixels.clone();
		var matrix:Matrix = new Matrix();
		matrix.identity();
		matrix.scale(scale, scale);
		data2.fillRect(data2.rect, FlxColor.TRANSPARENT);
		data2.draw(data, matrix, null, null, null, true);
		sprite.pixels = data2;

		luaSprites.set(toBeCalled, sprite);

		@:privateAccess
		{
			if (drawBehind)
			{
				PlayState.instance.removeObject(PlayState.gf);
				PlayState.instance.removeObject(PlayState.boyfriend);
				PlayState.instance.removeObject(PlayState.dad);
			}

			PlayState.instance.addObject(sprite);

			if (drawBehind)
			{
				PlayState.instance.addObject(PlayState.gf);
				PlayState.instance.addObject(PlayState.boyfriend);
				PlayState.instance.addObject(PlayState.dad);
			}
		}
		#end

		return toBeCalled;
	}

	public function die():Void
	{
		Lua.close(lua);
		lua = null;
	}

	function new()
	{
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();

		switch (songLowercase)
		{
			case "dad-battle": songLowercase = "dadbattle";
			case "philly-nice": songLowercase = "philly";
		}

		var result = LuaL.dofile(lua, Paths.lua(songLowercase + "/modchart"));

		if (result != 0)
		{
			var message:String = LuaHelper.readValue(lua, -1);
			Application.current.window.alert("LUA COMPILE ERROR:\n" + message, "Kade Engine Modcharts");
			lua = null;
			LoadingState.loadAndSwitchState(new MainMenuState());
			return;
		}

		setVar("difficulty", PlayState.storyDifficulty);
		setVar("bpm", Conductor.bpm);
		setVar("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		setVar("fpsCap", FlxG.save.data.fpsCap);
		setVar("downscroll", FlxG.save.data.downscroll);
		setVar("flashing", FlxG.save.data.flashing);
		setVar("distractions", FlxG.save.data.distractions);

		setVar("curStep", 0);
		setVar("curBeat", 0);
		setVar("crochet", Conductor.stepCrochet);
		setVar("safeZoneOffset", Conductor.safeZoneOffset);

		setVar("hudZoom", PlayState.instance.camHUD.zoom);
		setVar("cameraZoom", FlxG.camera.zoom);

		setVar("cameraAngle", FlxG.camera.angle);
		setVar("camHudAngle", PlayState.instance.camHUD.angle);

		setVar("followXOffset", 0);
		setVar("followYOffset", 0);

		setVar("showOnlyStrums", false);
		setVar("strumLine1Visible", true);
		setVar("strumLine2Visible", true);

		setVar("screenWidth", FlxG.width);
		setVar("screenHeight", FlxG.height);
		setVar("windowWidth", FlxG.width);
		setVar("windowHeight", FlxG.height);
		setVar("hudWidth", PlayState.instance.camHUD.width);
		setVar("hudHeight", PlayState.instance.camHUD.height);

		setVar("mustHit", false);

		setVar("strumLineY", PlayState.instance.strumLine.y);

		LuaHelper.addCallback(lua, "makeSprite", makeLuaSprite);
		LuaHelper.addCallback(lua, "changeDadCharacter", changeDadCharacter);
		LuaHelper.addCallback(lua, "changeBoyfriendCharacter", changeBoyfriendCharacter);
		LuaHelper.addCallback(lua, "getProperty", getPropertyByName);

		LuaHelper.addCallback(lua, "destroySprite", function(id:String):Bool
		{
			var sprite = luaSprites.get(id);

			if (sprite == null)
				return false;

			PlayState.instance.removeObject(sprite);
			return true;
		});

		LuaHelper.addCallback(lua, "setHudAngle", function(x:Float):Void
		{
			PlayState.instance.camHUD.angle = x;
		});

		LuaHelper.addCallback(lua, "setHealth", function(heal:Float):Void
		{
			PlayState.instance.health = heal;
		});

		LuaHelper.addCallback(lua, "setHudPosition", function(x:Int, y:Int):Void
		{
			PlayState.instance.camHUD.x = x;
			PlayState.instance.camHUD.y = y;
		});

		LuaHelper.addCallback(lua, "getHudX", function():Float
		{
			return PlayState.instance.camHUD.x;
		});

		LuaHelper.addCallback(lua, "getHudY", function():Float
		{
			return PlayState.instance.camHUD.y;
		});

		LuaHelper.addCallback(lua, "setCamPosition", function(x:Int, y:Int):Void
		{
			FlxG.camera.x = x;
			FlxG.camera.y = y;
		});

		LuaHelper.addCallback(lua, "getCameraX", function():Float
		{
			return FlxG.camera.x;
		});

		LuaHelper.addCallback(lua, "getCameraY", function():Float
		{
			return FlxG.camera.y;
		});

		LuaHelper.addCallback(lua, "setCamZoom", function(zoomAmount:Float):Void
		{
			FlxG.camera.zoom = zoomAmount;
		});

		LuaHelper.addCallback(lua, "setHudZoom", function(zoomAmount:Float):Void
		{
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		LuaHelper.addCallback(lua, "setStrumlineY", function(y:Float):Void
		{
			PlayState.instance.strumLine.y = y;
		});

		LuaHelper.addCallback(lua, "getRenderedNotes", function():Int
		{
			return PlayState.instance.notes.length;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteX", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].x;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteY", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].y;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteType", function(id:Int):Int
		{
			return PlayState.instance.notes.members[id].noteData;
		});

		LuaHelper.addCallback(lua, "isSustain", function(id:Int):Bool
		{
			return PlayState.instance.notes.members[id].isSustainNote;
		});

		LuaHelper.addCallback(lua, "isParentSustain", function(id:Int):Bool
		{
			return PlayState.instance.notes.members[id].prevNote.isSustainNote;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteParentX", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].prevNote.x;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteParentY", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].prevNote.y;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteHit", function(id:Int):Bool
		{
			return PlayState.instance.notes.members[id].mustPress;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteCalcX", function(id:Int):Float
		{
			if (PlayState.instance.notes.members[id].mustPress)
				return PlayState.playerStrums.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;

			return PlayState.strumLineNotes.members[Math.floor(Math.abs(PlayState.instance.notes.members[id].noteData))].x;
		});

		LuaHelper.addCallback(lua, "anyNotes", function():Bool
		{
			return PlayState.instance.notes.members.length != 0;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteStrumtime", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].strumTime;
		});

		LuaHelper.addCallback(lua, "getRenderedNoteScaleX", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].scale.x;
		});

		LuaHelper.addCallback(lua, "setRenderedNotePos", function(x:Float, y:Float, id:Int):Void
		{
			if (PlayState.instance.notes.members[id] == null)
				throw "Cannot set a rendered note position when it does not exist. ID: " + id;

			PlayState.instance.notes.members[id].modifiedByLua = true;
			PlayState.instance.notes.members[id].x = x;
			PlayState.instance.notes.members[id].y = y;
		});

		LuaHelper.addCallback(lua, "setRenderedNoteAlpha", function(alpha:Float, id:Int):Void
		{
			PlayState.instance.notes.members[id].modifiedByLua = true;
			PlayState.instance.notes.members[id].alpha = alpha;
		});

		LuaHelper.addCallback(lua, "setRenderedNoteScale", function(scale:Float, id:Int):Void
		{
			PlayState.instance.notes.members[id].modifiedByLua = true;
			PlayState.instance.notes.members[id].setGraphicSize(Std.int(PlayState.instance.notes.members[id].width * scale));
		});

		LuaHelper.addCallback(lua, "getRenderedNoteWidth", function(id:Int):Float
		{
			return PlayState.instance.notes.members[id].width;
		});

		LuaHelper.addCallback(lua, "setRenderedNoteAngle", function(angle:Float, id:Int):Void
		{
			PlayState.instance.notes.members[id].modifiedByLua = true;
			PlayState.instance.notes.members[id].angle = angle;
		});

		LuaHelper.addCallback(lua, "setActorX", function(x:Int, id:String):Void
		{
			getActorByName(id).x = x;
		});

		LuaHelper.addCallback(lua, "setActorAccelerationX", function(x:Int, id:String):Void
		{
			getActorByName(id).acceleration.x = x;
		});

		LuaHelper.addCallback(lua, "setActorDragX", function(x:Int, id:String):Void
		{
			getActorByName(id).drag.x = x;
		});

		LuaHelper.addCallback(lua, "setActorVelocityX", function(x:Int, id:String):Void
		{
			getActorByName(id).velocity.x = x;
		});

		LuaHelper.addCallback(lua, "playActorAnimation", function(id:String, anim:String, force:Bool, reverse:Bool):Void
		{
			getActorByName(id).playAnim(anim, force, reverse);
		});

		LuaHelper.addCallback(lua, "setActorAlpha", function(alpha:Float, id:String):Void
		{
			getActorByName(id).alpha = alpha;
		});

		LuaHelper.addCallback(lua, "setActorY", function(y:Int, id:String):Void
		{
			getActorByName(id).y = y;
		});

		LuaHelper.addCallback(lua, "setActorAccelerationY", function(y:Int, id:String):Void
		{
			getActorByName(id).acceleration.y = y;
		});

		LuaHelper.addCallback(lua, "setActorDragY", function(y:Int, id:String):Void
		{
			getActorByName(id).drag.y = y;
		});

		LuaHelper.addCallback(lua, "setActorVelocityY", function(y:Int, id:String):Void
		{
			getActorByName(id).velocity.y = y;
		});

		LuaHelper.addCallback(lua, "setActorAngle", function(angle:Int, id:String):Void
		{
			getActorByName(id).angle = angle;
		});

		LuaHelper.addCallback(lua, "setActorScale", function(scale:Float, id:String):Void
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scale));
		});

		LuaHelper.addCallback(lua, "setActorScaleXY", function(scaleX:Float, scaleY:Float, id:String):Void
		{
			getActorByName(id).setGraphicSize(Std.int(getActorByName(id).width * scaleX), Std.int(getActorByName(id).height * scaleY));
		});

		LuaHelper.addCallback(lua, "setActorFlipX", function(flip:Bool, id:String):Void
		{
			getActorByName(id).flipX = flip;
		});

		LuaHelper.addCallback(lua, "setActorFlipY", function(flip:Bool, id:String):Void
		{
			getActorByName(id).flipY = flip;
		});

		LuaHelper.addCallback(lua, "getActorWidth", function(id:String):Float
		{
			return getActorByName(id).width;
		});

		LuaHelper.addCallback(lua, "getActorHeight", function(id:String):Float
		{
			return getActorByName(id).height;
		});

		LuaHelper.addCallback(lua, "getActorAlpha", function(id:String):Float
		{
			return getActorByName(id).alpha;
		});

		LuaHelper.addCallback(lua, "getActorAngle", function(id:String):Float
		{
			return getActorByName(id).angle;
		});

		LuaHelper.addCallback(lua, "getActorX", function(id:String):Float
		{
			return getActorByName(id).x;
		});

		LuaHelper.addCallback(lua, "getActorY", function(id:String):Float
		{
			return getActorByName(id).y;
		});

		LuaHelper.addCallback(lua, "setWindowPos", function(x:Int, y:Int):Void
		{
			Application.current.window.x = x;
			Application.current.window.y = y;
		});

		LuaHelper.addCallback(lua, "getWindowX", function():Float
		{
			return Application.current.window.x;
		});

		LuaHelper.addCallback(lua, "getWindowY", function():Float
		{
			return Application.current.window.y;
		});

		LuaHelper.addCallback(lua, "resizeWindow", function(width:Int, height:Int):Void
		{
			Application.current.window.resize(width, height);
		});

		LuaHelper.addCallback(lua, "getScreenWidth", function():Float
		{
			return Application.current.window.display.currentMode.width;
		});

		LuaHelper.addCallback(lua, "getScreenHeight", function():Float
		{
			return Application.current.window.display.currentMode.height;
		});

		LuaHelper.addCallback(lua, "getWindowWidth", function():Float
		{
			return Application.current.window.width;
		});

		LuaHelper.addCallback(lua, "getWindowHeight", function():Float
		{
			return Application.current.window.height;
		});

		LuaHelper.addCallback(lua, "tweenCameraPos", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraAngle", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraZoom", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {zoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudPos", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudAngle", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudZoom", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {zoom: toZoom}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenPos", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosXAngle", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosYAngle", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenAngle", function(id:String, toAngle:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
				ease: FlxEase.linear,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraAngleOut", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraZoomOut", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {zoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudPosOut", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudAngleOut", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudZoomOut", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {zoom: toZoom}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosOut", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosXAngleOut", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosYAngleOut", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenAngleOut", function(id:String, toAngle:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
				ease: FlxEase.cubeOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraAngleIn", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenCameraZoomIn", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(FlxG.camera, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudPosIn", function(toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudAngleIn", function(toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenHudZoomIn", function(toZoom:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(PlayState.instance.camHUD, {zoom: toZoom}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, ["camera"])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosIn", function(id:String, toX:Int, toY:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, y: toY}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosXAngleIn", function(id:String, toX:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {x: toX, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenPosYAngleIn", function(id:String, toY:Int, toAngle:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {y: toY, angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenAngleIn", function(id:String, toAngle:Int, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {angle: toAngle}, time, {
				ease: FlxEase.cubeIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenFadeIn", function(id:String, toAlpha:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circIn,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		LuaHelper.addCallback(lua, "tweenFadeOut", function(id:String, toAlpha:Float, time:Float, onComplete:String):Void
		{
			FlxTween.tween(getActorByName(id), {alpha: toAlpha}, time, {
				ease: FlxEase.circOut,
				onComplete: function(flxTween:FlxTween) if (onComplete != "" && onComplete != null) callLua(onComplete, [id])
			});
		});

		for (i in 0...PlayState.strumLineNotes.length)
		{
			var member = PlayState.strumLineNotes.members[i];

			setVar("defaultStrum" + i + "X", Math.floor(member.x));
			setVar("defaultStrum" + i + "Y", Math.floor(member.y));
			setVar("defaultStrum" + i + "Angle", Math.floor(member.angle));
		}
	}

	public function executeState(name:String, args:Array<Dynamic>):String
	{
		return callLua(name, args);
	}

	public static function createModChartState():ModChartState
	{
		return new ModChartState();
	}
}
#end
