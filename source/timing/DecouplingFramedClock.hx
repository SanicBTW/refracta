package timing;

import scopes.Protect;

class DecouplingFramedClock implements ISourceChangeableClock implements IAdjustableClock implements IFrameBasedClock
{
	public var allowDecoupling:Bool = true;

	private var _source:IClock;

	public var source(get, never):IClock;

	@:noCompletion
	private function get_source():IClock
		return _source;

	private var _running:Bool = true;

	public var running(get, never):Bool;

	@:noCompletion
	private function get_running():Bool
		return _running;

	private var _currentTime:Float = 0; // maps to CurrentTime

	public var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return _currentTime;

	private var _elapsedFrameTime:Float = 0;

	public var elapsedFrameTime(get, never):Float;

	@:noCompletion
	private function get_elapsedFrameTime():Float
		return _elapsedFrameTime;

	public var rate(get, set):Float;

	@:noCompletion
	private function get_rate():Float
		return adjustableSourceClock.rate;

	@:noCompletion
	private function set_rate(value:Float):Float
		return adjustableSourceClock.rate = value;

	public var timeInfo(get, never):FrameTimeInfo;

	@:noCompletion
	private function get_timeInfo():FrameTimeInfo
		return {elapsed: elapsedFrameTime, current: currentTime};

	public var framesPerSecond(get, never):Float;

	@:noCompletion
	private function get_framesPerSecond():Float
		return 0;

	private var shouldBeRunning:Bool;
	private var decoupledTime:Float; // maps to currentTime
	private var lastRefTime:Null<Float>;
	private var lastSeekFailed:Bool;

	private final realtimeRefClock:RealTimeClock = new RealTimeClock(true);
	private var adjustableSourceClock:IAdjustableClock;

	// addition!! now has the latest changes
	private var pendingSourceRestartAfterNegativeSeek:Bool = false;

	public function new(?source:IClock = null)
	{
		changeSource(source);
		if (this.source == null)
			throw "Source was null";
	}

	public function processFrame()
	{
		final lastTime:Float = currentTime;

		if (source is IFrameBasedClock)
			cast(source, IFrameBasedClock).processFrame();

		var referenceTime = realtimeRefClock.currentTime;

		Protect.protect({
			if (source.running)
			{
				decoupledTime = source.currentTime;
				shouldBeRunning = true;
				return;
			}

			if (!allowDecoupling)
			{
				decoupledTime = source.currentTime;
				shouldBeRunning = false;
			}

			if (!shouldBeRunning)
				return;

			if (lastRefTime == null)
				return;

			final elapsedRefTime:Float = (referenceTime - lastRefTime) * rate;
			decoupledTime += elapsedRefTime;

			if (pendingSourceRestartAfterNegativeSeek && decoupledTime >= 0)
			{
				pendingSourceRestartAfterNegativeSeek = false;

				lastSeekFailed = !adjustableSourceClock.seek(decoupledTime);
				if (!lastSeekFailed)
					adjustableSourceClock.start();
			}
		}, {
			_running = shouldBeRunning;
			lastRefTime = referenceTime;
			_currentTime = decoupledTime;
			_elapsedFrameTime = _currentTime - lastTime;
		});
	}

	public function changeSource(source:IClock)
	{
		_source = source ?? new RealTimeClock(true);

		if (!(_source is IAdjustableClock))
			throw "Clock must be of type IAdjustableFrameClock";

		adjustableSourceClock = cast _source;
		decoupledTime = adjustableSourceClock.currentTime;
		shouldBeRunning = adjustableSourceClock.running;
		lastSeekFailed = false;
	}

	public function reset()
	{
		adjustableSourceClock.reset();
		pendingSourceRestartAfterNegativeSeek = false;
		shouldBeRunning = false;
		lastSeekFailed = false;
		decoupledTime = 0;
	}

	public function start()
	{
		if (shouldBeRunning)
			return;

		if (lastSeekFailed && allowDecoupling)
		{
			shouldBeRunning = true;
			return;
		}

		adjustableSourceClock.start();
		shouldBeRunning = adjustableSourceClock.running || allowDecoupling;
	}

	public function stop()
	{
		adjustableSourceClock.stop();
		shouldBeRunning = false;
	}

	public function seek(position:Float):Bool
	{
		lastSeekFailed = !adjustableSourceClock.seek(position);

		if (!lastSeekFailed)
		{
			if (shouldBeRunning && !source.running)
				adjustableSourceClock.start();
		}
		else
		{
			if (!allowDecoupling)
				return false;

			adjustableSourceClock.stop();
			pendingSourceRestartAfterNegativeSeek = position < 0;
		}

		decoupledTime = position;
		return true;
	}

	public function resetSpeedAdjustments()
	{
		adjustableSourceClock.resetSpeedAdjustments();
	}
}
