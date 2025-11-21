package timing;

class OffsetClock implements IClock
{
	private var source:IClock;

	public var offset:Float;

	public var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return source.currentTime + offset;

	public var rate(get, never):Float;

	@:noCompletion
	private function get_rate():Float
		return source.rate;

	public var running(get, never):Bool;

	@:noCompletion
	private function get_running():Bool
		return source.running;

	public function new(source:IClock)
	{
		this.source = source;
	}
}
