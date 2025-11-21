package platform.native;

import haxe.Timer;
import sys.thread.Thread;
import timing.RealTimeClock;

class SysClock
{
	private final thread:Thread;
	private final source:RealTimeClock;

	public function new(source:RealTimeClock)
	{
		this.source = source;
		thread = Thread.createWithEventLoop(runLoop);
	}

	// keep running the clock
	private function runLoop()
	{
		while (true)
		{
			if (source.running)
				source.tick(Timer.stamp() * 1000);

			Sys.sleep(1 / 1000);
		}
	}
}
