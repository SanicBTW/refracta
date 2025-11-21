package timing;

interface IAdjustableClock extends IClock
{
	function reset():Void;
	function start():Void;
	function stop():Void;
	function seek(position:Float):Bool;
	function resetSpeedAdjustments():Void;

	var rate(get, set):Float;
}
