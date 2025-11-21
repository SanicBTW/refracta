package timing;

class ManualFramedClock implements IFrameBasedClock
{
	public var currentTime(get, set):Float;

	private var _currentTime:Float;

	@:noCompletion
	private function get_currentTime():Float
		return _currentTime;

	@:noCompletion
	private function set_currentTime(value:Float):Float
		return _currentTime = value;

	public var elapsedFrameTime(get, set):Float;

	private var _elapsedFrameTime:Float;

	@:noCompletion
	private function get_elapsedFrameTime():Float
		return _elapsedFrameTime;

	@:noCompletion
	private function set_elapsedFrameTime(value:Float):Float
		return _elapsedFrameTime = value;

	public var framesPerSecond(get, set):Float;

	private var _framesPerSecond:Float;

	@:noCompletion
	private function get_framesPerSecond():Float
		return _framesPerSecond;

	@:noCompletion
	private function set_framesPerSecond(value:Float):Float
		return _framesPerSecond = value;

	public var timeInfo(get, never):FrameTimeInfo;

	@:noCompletion
	private function get_timeInfo():FrameTimeInfo
		return {elapsed: elapsedFrameTime, current: currentTime};

	public var rate(get, set):Float;

	private var _rate:Float;

	@:noCompletion
	private function get_rate():Float
		return _rate;

	@:noCompletion
	private function set_rate(value:Float):Float
		return _rate = value;

	public var running(get, set):Bool;

	private var _running:Bool;

	@:noCompletion
	private function get_running():Bool
		return _running;

	@:noCompletion
	private function set_running(value:Bool):Bool
		return _running = value;

	public function processFrame():Void {}

	public function new() {}
}
