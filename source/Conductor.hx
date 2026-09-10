package;

import Song.SwagSong;
import flixel.FlxG;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = (60 / bpm) * 1000;
	public static var stepCrochet:Float = crochet / 4;
	public static var songPosition:Float = 0;
	public static var lastSongPos:Float = 0;
	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function recalculateTimings():Void
	{
		safeFrames = FlxG.save.data.frames;
		safeZoneOffset = Math.floor((safeFrames / 60) * 1000);
		timeScale = safeZoneOffset / 166;
	}

	public static function mapBPMChanges(song:SwagSong):Void
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		bpmChangeMap.push({stepTime: 0, songTime: 0, bpm: curBPM});

		for (i in 0...song.notes.length)
		{
			var section = song.notes[i];

			if (section.changeBPM && section.bpm != curBPM)
			{
				curBPM = section.bpm;
				bpmChangeMap.push({stepTime: totalSteps, songTime: totalPos, bpm: curBPM});
			}

			var deltaSteps:Int = section.lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBpm:Float):Void
	{
		bpm = newBpm;
		crochet = (60 / bpm) * 1000;
		stepCrochet = crochet / 4;
	}

	public static function getBPMFromSeconds(time:Float):Float
	{
		var event = getEventAtTime(time);
		return event != null ? event.bpm : bpm;
	}

	public static function getStepAtTime(time:Float):Float
	{
		var event = getEventAtTime(time);
		if (event == null)
			return time / stepCrochet;

		var eventStepCrochet = (60 / event.bpm) * 1000 / 4;
		return event.stepTime + (time - event.songTime) / eventStepCrochet;
	}

	public static function getTimeAtStep(step:Float):Float
	{
		var event = getEventAtStep(step);
		if (event == null)
			return step * stepCrochet;

		var eventStepCrochet = (60 / event.bpm) * 1000 / 4;
		return event.songTime + (step - event.stepTime) * eventStepCrochet;
	}

	static function getEventAtTime(time:Float):BPMChangeEvent
	{
		if (bpmChangeMap.length == 0)
			return null;

		var result = bpmChangeMap[0];
		for (event in bpmChangeMap)
		{
			if (event.songTime > time)
				break;
			result = event;
		}
		return result;
	}

	static function getEventAtStep(step:Float):BPMChangeEvent
	{
		if (bpmChangeMap.length == 0)
			return null;

		var result = bpmChangeMap[0];
		for (event in bpmChangeMap)
		{
			if (event.stepTime > step)
				break;
			result = event;
		}
		return result;
	}

	public static var currentStep(get, never):Int;

	static function get_currentStep():Int
	{
		return Math.floor(getStepAtTime(songPosition));
	}

	public static var currentBeat(get, never):Int;

	static function get_currentBeat():Int
	{
		return Std.int(currentStep / 4);
	}
}
