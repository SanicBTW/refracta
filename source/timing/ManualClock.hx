package timing;

class ManualClock implements IClock
{
	public var currentTime(get, set):Float;

	private var _currentTime:Float;

	@:noCompletion
	private function get_currentTime():Float
		return _currentTime;

	@:noCompletion
	private function set_currentTime(value:Float):Float
		return _currentTime = value;

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

	public function new() {}
}
