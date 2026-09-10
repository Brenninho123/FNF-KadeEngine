package;

import hxlua.Lua;
import hxlua.LuaL;
import hxlua.Types;
import cpp.RawPointer;

class LuaHelper
{
	static var callbacks:Map<String, Dynamic> = [];

	public static function addCallback(l:RawPointer<Lua_State>, name:String, fn:Dynamic):Void
	{
		callbacks.set(name, fn);

		Lua.pushstring(l, name);
		Lua.pushcclosure(l, cpp.Function.fromStaticFunction(dispatch), 1);
		Lua.setglobal(l, name);
	}

	static function dispatch(l:RawPointer<Lua_State>):Int
	{
		var name:String = Lua.tostring(l, Lua.upvalueindex(1));
		var fn:Dynamic = callbacks.get(name);

		if (fn == null)
		{
			LuaL.error(l, "No callback registered for this function", []);
			return 0;
		}

		var argCount:Int = Lua.gettop(l);
		var args:Array<Dynamic> = [];

		for (i in 1...argCount + 1)
			args.push(readValue(l, i));

		var result:Dynamic = Reflect.callMethod(null, fn, args);

		return pushDynamic(l, result) ? 1 : 0;
	}

	public static function readValue(l:RawPointer<Lua_State>, index:Int):Dynamic
	{
		return switch (Lua.type(l, index))
		{
			case t if (t == Lua.TBOOLEAN): Lua.toboolean(l, index) != 0;
			case t if (t == Lua.TNUMBER): (Lua.tonumber(l, index) : Float);
			case t if (t == Lua.TSTRING): (Lua.tostring(l, index) : String);
			default: null;
		}
	}

	public static function pushDynamic(l:RawPointer<Lua_State>, value:Dynamic):Bool
	{
		if (value == null)
			return false;

		switch (Type.typeof(value))
		{
			case TBool:
				Lua.pushboolean(l, (value : Bool) ? 1 : 0);
			case TInt, TFloat:
				Lua.pushnumber(l, value);
			case TClass(String):
				Lua.pushstring(l, value);
			case TClass(Array):
				pushArray(l, value);
			case TObject:
				pushObject(l, value);
			default:
				return false;
		}

		return true;
	}

	static function pushArray(l:RawPointer<Lua_State>, array:Array<Dynamic>):Void
	{
		Lua.createtable(l, array.length, 0);

		for (i in 0...array.length)
		{
			Lua.pushnumber(l, i + 1);
			pushDynamic(l, array[i]);
			Lua.settable(l, -3);
		}
	}

	static function pushObject(l:RawPointer<Lua_State>, object:Dynamic):Void
	{
		var fields = Reflect.fields(object);

		Lua.createtable(l, 0, fields.length);

		for (field in fields)
		{
			Lua.pushstring(l, field);
			pushDynamic(l, Reflect.field(object, field));
			Lua.settable(l, -3);
		}
	}
}
