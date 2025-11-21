package timing;

interface IFrameBasedClock extends IClock
{
	var elapsedFrameTime(get, never):Float;
	var framesPerSecond(get, never):Float;
	var timeInfo(get, never):FrameTimeInfo;

	function processFrame():Void;
}
