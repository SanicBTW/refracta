package timing;

import scopes.Protect;

class InterpolatingFramedClock implements IFrameBasedClock implements ISourceChangeableClock
{
	public var allowableErrorMilliseconds = 1000 / 60 * 2;

	private var _isInterpolating:Bool;

	public var isInterpolating(get, never):Bool;

	@:noCompletion
	private function get_isInterpolating():Bool
		return _isInterpolating;

	public var drift(get, never):Float;

	@:noCompletion
	private function get_drift():Float
		return Math.max(currentTime - framedSourceClock.currentTime, 0.00001);

	private var _running:Bool = true;

	public var running(get, never):Bool;

	@:noCompletion
	private function get_running():Bool
		return _running;

	private var framedSourceClock:IFrameBasedClock;

	private var _source:IClock;

	public var source(get, never):IClock;

	@:noCompletion
	private function get_source():IClock
		return _source;

	private var _currentTime:Float = 0; // maps to CurrentTime in the c# version

	public var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return _currentTime;

	public var rate(get, never):Float;

	@:noCompletion
	private function get_rate():Float
		return source.rate;

	private var _elapsedFrameTime:Float = 0;

	public var elapsedFrameTime(get, never):Float;

	@:noCompletion
	private function get_elapsedFrameTime():Float
		return _elapsedFrameTime;

	public var timeInfo(get, never):FrameTimeInfo;

	@:noCompletion
	private function get_timeInfo():FrameTimeInfo
		return {elapsed: elapsedFrameTime, current: currentTime};

	public var framesPerSecond(get, never):Float;

	@:noCompletion
	private function get_framesPerSecond():Float
		return 0; // https://github.com/ppy/osu-framework/blob/f647eeb22549a72e84e5a95d39b6b1bcd09f4830/osu.Framework/Timing/InterpolatingFramedClock.cs#L141

	private final realtimeClock:FramedClock = new FramedClock(new RealTimeClock(true));
	private var interCurrentTime:Float; // maps into currentTime in the c# version

	public function new(?source:IFrameBasedClock = null)
	{
		changeSource(source);
		if (this.source == null)
			throw "Source was null";
	}

	public function changeSource(source:IClock)
	{
		_source = source ?? new RealTimeClock(true);

		if (_source is IFrameBasedClock)
			framedSourceClock = cast _source;
		else
			framedSourceClock = new FramedClock(_source);

		_isInterpolating = false;
		interCurrentTime = framedSourceClock.currentTime;
	}

	public function processFrame()
	{
		final lastTime:Float = interCurrentTime;

		realtimeClock.processFrame();
		framedSourceClock.processFrame();

		final sourceIsRunning:Bool = framedSourceClock.running;
		final sourceHasElapsed:Bool = framedSourceClock.elapsedFrameTime != 0;

		Protect.protect({
			if (!sourceIsRunning)
			{
				if (sourceHasElapsed)
				{
					_isInterpolating = false;
					interCurrentTime = framedSourceClock.currentTime;
				}

				return;
			}

			if (isInterpolating)
			{
				interCurrentTime += realtimeClock.elapsedFrameTime * rate;
				interCurrentTime += (framedSourceClock.currentTime - interCurrentTime) / 8;

				final withinAllowableError:Bool = Math.abs(framedSourceClock.currentTime - interCurrentTime) <= allowableErrorMilliseconds * rate;
				if (!withinAllowableError)
				{
					_isInterpolating = false;
					_currentTime = framedSourceClock.currentTime;
				}
			}
			else
			{
				interCurrentTime = framedSourceClock.currentTime;

				if (sourceHasElapsed)
					_isInterpolating = true;
			}

			final elapsedInOpposingDirection:Bool = framedSourceClock.elapsedFrameTime != 0
				&& sign(framedSourceClock.elapsedFrameTime) != sign(rate);
			if (!elapsedInOpposingDirection)
				interCurrentTime = rate >= 0 ? Math.max(lastTime, interCurrentTime) : Math.min(lastTime, interCurrentTime);
		}, {
			_running = sourceIsRunning;
			_currentTime = interCurrentTime;
			_elapsedFrameTime = currentTime - lastTime;
		});
	}

	// i should make a helper class for math stuff really
	// previously, the sign call would just use the js math sign instead of this, uhh funny right?
	private static function sign(x:Float):Int
	{
		// using native impl cuz im cool like that
		#if js
		return js.lib.Math.sign(x);
		#else
		if (x > 0) // (0, x]
			return 1;

		if (x < 0) // [x, 0)
			return -1;

		return x; // 0 or -0 could be
		#end
	}
}
