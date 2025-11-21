package timing;

import haxe.Int32;
#if js
import platform.web.WebClock;
#end
#if sys
import platform.native.SysClock;
#end

// this is the ABSTRACTION over the native implementation of the realtime clock
class RealTimeClock implements IAdjustableClock
{
	public static final frequency:Int = 1000;

	private var seekOffset:Float = 0;
	private var rateChangeUsed:Float = 0;
	private var rateChangeAccumulated:Float = 0;

	private var _rate:Float = 1;

	public var rate(get, set):Float;

	@:noCompletion
	private function get_rate():Float
		return _rate;

	@:noCompletion
	private function set_rate(value:Float):Float
	{
		if (rate == value)
			return _rate;

		rateChangeAccumulated += (clockMilliseconds - rateChangeUsed) * rate;
		rateChangeUsed = clockMilliseconds;

		return _rate = value;
	}

	// implementation of IClock
	public var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return clockCurrentTime + seekOffset;

	private var _running:Bool;

	public var running(get, never):Bool;

	@:noCompletion
	private function get_running():Bool
		return _running;

	// timing
	private var lastFrameTime:Float = 0;
	private var elapsedTicks:Int32 = 0;

	private var clockCurrentTime(get, never):Float;

	@:noCompletion
	private function get_clockCurrentTime():Float
		return (clockMilliseconds - rateChangeUsed) * rate + rateChangeAccumulated;

	private var clockMilliseconds(get, never):Float;

	@:noCompletion
	private function get_clockMilliseconds():Float
		return elapsedTicks / frequency * 1000;

	public function new(startClock:Bool = false)
	{
		#if sys new SysClock(this); #elseif js new WebClock(this); #end

		if (startClock)
			start();
	}

	public function start()
	{
		if (_running)
			return;

		_running = true;
	}

	public function reset():Void
	{
		resetAccumulatedRate();
	}

	public function stop()
	{
		if (!_running)
			return;

		_running = false;
	}

	public function restart():Void
	{
		resetAccumulatedRate();
	}

	public function resetSpeedAdjustments()
	{
		rate = 1;
	}

	public function seek(position:Float):Bool
	{
		seekOffset = position - clockCurrentTime;
		return true;
	}

	private function resetAccumulatedRate()
	{
		rateChangeAccumulated = 0;
		rateChangeUsed = 0;
	}

	#if js
	@:allow(platform.web.WebClock)
	#elseif sys
	@:allow(platform.native.SysClock)
	#end
	private function tick(timeStamp:Float)
	{
		if (!_running)
			return;

		var delta:Int = Math.floor(timeStamp - lastFrameTime);
		elapsedTicks += delta;
		lastFrameTime = timeStamp;

		onTick();
	}

	public dynamic function onTick():Void {}
}
