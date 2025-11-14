package threading;

// https://github.com/ppy/osu-framework/blob/0c8bac9b65bbbbb5e1f2f2b5ea4bed59baa4b620/osu.Framework/Threading/ScheduledDelegate.cs#L9
enum RunState
{
	WAITING;
	RUNNING;
	COMPLETE;
	CANCELLED;
}

class ScheduledDelegate
{
	private var _executionTime:Float;

	public var executionTime(get, never):Float;

	@:noCompletion
	private function get_executionTime()
		return _executionTime;

	public final repeatInterval:Float;

	public var performRepeatCatchUpExecutions:Bool = true;
	public var completed(get, never):Bool;

	@:noCompletion
	private function get_completed():Bool
		return state == RunState.COMPLETE;

	public var cancelled(get, never):Bool;

	@:noCompletion
	private function get_cancelled():Bool
		return state == RunState.CANCELLED;

	// this had a funny comment in the original files, just for the sake of letting yall know how much time i spent on this ill be adding it for fun
	// sanco here. after a whole day of searching WHY THE FUCK THE: SCHEDULER AND THIS WASNT WORKING
	// first, the queue i ported over, then revising the scheduler and now...
	// it was just setting this field to its default value. god i miss the default init from c# fuck
	private var _state:RunState = RunState.WAITING;

	public var state(get, never):RunState;

	@:noCompletion
	private function get_state():RunState
		return _state;

	private var task:Void->Void;

	public function new(task:Void->Void, executionTime:Float = 0, repeatInterval:Float = -1)
	{
		this.task = task;
		this._executionTime = executionTime;
		this.repeatInterval = repeatInterval;
	}

	public function runTask()
	{
		if (cancelled)
			throw "Can not run a ScheduledDelegate that has been cancelled.";

		if (completed)
			throw "Can not run a ScheduledDelegate that has been already completed.";

		runInternalTask();
	}

	private function runInternalTask()
	{
		if (state != RunState.WAITING)
			return;

		_state = RUNNING;

		#if SCHEDULED_TASK_WRAP
		try
		{
			invokeTask();
		}
		catch (ex)
		{
			// should i do my own trace library or use another library?
			trace(' [refracta/error] - Caught an unhandled exception inside a ${Type.getClassName(Type.getClass(this))}');
			trace(ex);
			cancel(); // cancel further executions
		}
		#else
		invokeTask();
		#end

		if (state == RunState.CANCELLED)
			return;

		if (state != RunState.RUNNING)
			trace(" [refracta/debug] - Task state is not running.");

		_state = RunState.COMPLETE;
	}

	private function invokeTask()
	{
		if (task == null)
			return;

		task();
	}

	public function cancel()
	{
		_state = RunState.CANCELLED;
	}

	private function setNextExecution(currentTime:Null<Float>)
	{
		if (_state == RunState.CANCELLED)
			return;

		_state = RunState.WAITING;

		if (currentTime == null)
			return;

		_executionTime += repeatInterval;

		if (executionTime < currentTime && !performRepeatCatchUpExecutions)
			_executionTime = currentTime + repeatInterval;
	}
}
