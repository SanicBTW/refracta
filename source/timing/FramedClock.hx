package timing;

import haxe.Int32;

class FramedClock implements IFrameBasedClock implements ISourceChangeableClock
{
	private var _source:IClock;

	public var source(get, never):IClock;

	@:noCompletion
	private function get_source():IClock
		return _source;

	private final maxFramesTimes:Int = 128;
	private final betweenFrameTimes:Array<Float> = [];

	private var totalFramesProcessed:Int32 = 0;

	private var _framesPerSecond:Float = 0;

	public var framesPerSecond(get, never):Float;

	@:noCompletion
	private function get_framesPerSecond():Float
		return _framesPerSecond;

	private var _jitter:Float = 0;

	public var jitter(get, never):Float;

	@:noCompletion
	private function get_jitter():Float
		return _jitter;

	private var _currentTime:Float = 0;

	public var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return _currentTime;

	private var lastFrameTime:Float = 0;

	public var rate(get, never):Float;

	@:noCompletion
	private function get_rate():Float
		return source.rate;

	private var sourceTime(get, never):Float;

	@:noCompletion
	private function get_sourceTime():Float
		return source.currentTime;

	public var elapsedFrameTime(get, never):Float;

	@:noCompletion
	private function get_elapsedFrameTime():Float
		return currentTime - lastFrameTime;

	public var running(get, never):Bool;

	@:noCompletion
	private function get_running():Bool
		return source.running;

	public var timeInfo(get, never):FrameTimeInfo;

	@:noCompletion
	private function get_timeInfo():FrameTimeInfo
		return {elapsed: elapsedFrameTime, current: currentTime};

	private var timeUntilNextCalculation:Float = 0;
	private var timeSinceLastCalculation:Float = 0;
	private var framesSinceLastCalculation:Int = 0;

	private static final fps_calculation_interval:Int = 250;

	private final processSource:Bool;

	public function new(source:IClock = null, processSource:Bool = true)
	{
		this.processSource = processSource;

		changeSource(source ?? new RealTimeClock(true));
	}

	public function changeSource(source:IClock)
	{
		_source = source;
		_currentTime = lastFrameTime = source.currentTime;
	}

	public function processFrame()
	{
		betweenFrameTimes[totalFramesProcessed % maxFramesTimes] = currentTime - lastFrameTime;
		totalFramesProcessed++;

		if (processSource && source is IFrameBasedClock)
			cast(source, IFrameBasedClock).processFrame();

		if (timeUntilNextCalculation <= 0)
		{
			timeUntilNextCalculation += fps_calculation_interval;

			if (framesSinceLastCalculation == 0)
			{
				_framesPerSecond = 0;
				_jitter = 0;
			}
			else
			{
				_framesPerSecond = Math.ceil(framesSinceLastCalculation * 1000 / timeSinceLastCalculation);

				var sum:Float = 0;
				var sumOfSquares:Float = 0;

				for (v in betweenFrameTimes)
				{
					sum += v;
					sumOfSquares += v * v;
				}

				var avg:Float = sum / maxFramesTimes;
				var variance:Float = (sumOfSquares / maxFramesTimes) - (avg * avg);
				_jitter = Math.sqrt(variance);
			}

			timeSinceLastCalculation = framesSinceLastCalculation = 0;
		}

		framesSinceLastCalculation++;
		timeUntilNextCalculation -= elapsedFrameTime;
		timeSinceLastCalculation += elapsedFrameTime;

		lastFrameTime = currentTime;
		_currentTime = sourceTime;
	}
}
