package timing;

class FramedOffsetClock extends FramedClock
{
	override function get_currentTime():Float
		return _currentTime + offset;

	private var _offset:Float;

	public var offset(get, set):Float;

	@:noCompletion
	private function get_offset():Float
		return _offset;

	@:noCompletion
	private function set_offset(value:Float):Float
	{
		lastFrameTime += value - offset;
		return _offset = value;
	}
}
