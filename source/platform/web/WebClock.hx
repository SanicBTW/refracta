package platform.web;

import core.IDisposable;
import js.Browser;
import timing.RealTimeClock;

class WebClock implements IDisposable
{
	private final source:RealTimeClock;
	private var frameHandle:Int;

	public function new(source:RealTimeClock)
	{
		this.source = source;
		frameHandle = Browser.window.requestAnimationFrame(tick);
	}

	public function dispose()
		Browser.window.cancelAnimationFrame(frameHandle);

	private function tick(timeStamp:Float)
	{
		if (source.running)
			source.tick(timeStamp);

		frameHandle = Browser.window.requestAnimationFrame(tick);
	}
}
