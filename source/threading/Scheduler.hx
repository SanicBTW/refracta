package threading;

import core.Ref;
import ds.Queue;
import hx.injection.Service;
import timing.IClock;

using extensions.ArrayExtensions;

// https://github.com/ppy/osu-framework/blob/0c8bac9b65bbbbb5e1f2f2b5ea4bed59baa4b620/osu.Framework/Threading/Scheduler.cs
// this should be a service, or not? maybe bound to the basic objects, yah
// my previous scheduler didn't implement the scheduled delegates with data, this is new work from me :D!
// an attempt to port osu!framework scheduler
class Scheduler implements Service
{
	private static final log_excessive_queue_length_interval:Int = 1000;

	private final runQueue:Queue<ScheduledDelegate> = new Queue<ScheduledDelegate>();
	private final timedTasks:Array<ScheduledDelegate> = [];
	private final perUpdateTasks:Array<ScheduledDelegate> = [];

	private final tasksToSchedule:Array<ScheduledDelegate> = [];
	private final tasksToRemove:Array<ScheduledDelegate> = [];

	private var clock:IClock;

	private var currentTime(get, never):Float;

	@:noCompletion
	private function get_currentTime():Float
		return clock != null ? clock.currentTime : 0;

	private var totalPendingTasks(get, never):Int;

	@:noCompletion
	private function get_totalPendingTasks():Int
		return runQueue.length + timedTasks.length + perUpdateTasks.length;

	public var hasPendingTasks(get, never):Bool;

	@:noCompletion
	private function get_hasPendingTasks():Bool
		return totalPendingTasks > 0;

	private var _totalTasksRun:Int = 0;

	public var totalTasksRun(get, never):Int;

	@:noCompletion
	private function get_totalTasksRun():Int
		return _totalTasksRun;

	// because of saving it as a service i cannot pass constructor arguments
	public function new() {}

	public function updateClock(newClock:IClock)
	{
		if (newClock == clock)
			return;

		// This is the first time we will get a valid time, so assume this is the
		// reference point everything scheduled so far starts from.
		if (clock == null)
		{
			#if debug
			trace('[refracta/scheduler] Changed the scheduler clock. Starting on time ${newClock.currentTime}');
			#end
			for (s in timedTasks)
				s._executionTime += newClock.currentTime;
		}

		clock = newClock;
	}

	public function update():Int
	{
		final hasTimedTasks:Bool = timedTasks.length > 0;
		final hasPerUpdateTasks:Bool = perUpdateTasks.length > 0;

		if (hasTimedTasks || hasPerUpdateTasks)
		{
			#if SCHEDULER_LOG
			trace('[refracta/scheduler] queueing new tasks');
			#end
			queueTimedTasks();
			queuePerUpdateTasks();
		}

		final countToRun:Int = runQueue.length;

		if (countToRun == 0)
			return 0;

		var countRun:Int = 0;

		final sdRef:Ref<Null<ScheduledDelegate>> = new Ref(null);
		while (getNextTask(sdRef))
		{
			final sd:Null<ScheduledDelegate> = sdRef.deref();
			if (sd == null)
				break; // no schedule delegate available within the queue

			sd.runInternalTask();

			_totalTasksRun++;

			if (++countRun == countToRun)
				break;
		}

		#if SCHEDULER_LOG
		trace('[refracta/scheduler] Finished updating scheduler - Tasks ran ${countRun}');
		#end

		return countRun;
	}

	public function cancelDelayedTasks()
	{
		for (t in timedTasks)
			t.cancel();

		timedTasks.resize(0);
	}

	public function add(task:Void->Void):ScheduledDelegate
	{
		final del:ScheduledDelegate = new ScheduledDelegate(task);
		enqueue(del);
		return del;
	}

	@:generic
	public function addWithData<T>(task:T->Void, data:T):ScheduledDelegate
	{
		final del:ScheduledDelegateWithData<T> = new ScheduledDelegateWithData<T>(task, data);
		enqueue(del);
		return del;
	}

	public function addScheduled(task:ScheduledDelegate)
	{
		if (task.completed)
			throw "Can not add a ScheduledDelegate that has been already completed";

		timedTasks.addInPlace(task);

		if (timedTasks.length % log_excessive_queue_length_interval == 0)
		{
			trace('[refracta/scheduler] this Scheduler has ${timedTasks.length} timed tasks pending');
			trace('[refracta/scheduler] - first task: ${timedTasks[0]}');
			trace('[refracta/scheduler] - last task: ${timedTasks[timedTasks.length - 1]}');
		}
	}

	public function addDelayed(task:Void->Void, timeUntilRun:Float = 0, repeat:Bool = false):ScheduledDelegate
	{
		final del:ScheduledDelegate = new ScheduledDelegate(task, currentTime + timeUntilRun, repeat ? timeUntilRun : -1);
		addScheduled(del);
		return del;
	}

	@:generic
	public function addDelayedWithData<T>(task:T->Void, data:T, timeUntilRun:Float = 0, repeat:Bool = false):ScheduledDelegate
	{
		final del:ScheduledDelegateWithData<T> = new ScheduledDelegateWithData<T>(task, data, currentTime + timeUntilRun, repeat ? timeUntilRun : -1);
		addScheduled(del);
		return del;
	}

	public function addOnce(task:Void->Void):Bool
	{
		for (t in runQueue)
			if (t.task == task)
				return false;

		enqueue(new ScheduledDelegate(task));
		return true;
	}

	// the generic metadata is needed for the type check, not efficient but the only thing i found working
	// please check https://try.haxe.org/#253436d0 for the testing of this code,
	// i thought of using casting and then let it fail (return a null object on cast) but it didnt work as expected

	@:generic
	public function addOnceWithData<T>(task:T->Void, data:T):Bool
	{
		var targetCls:ScheduledDelegateWithData<T> = new ScheduledDelegateWithData<T>(task, data);
		var targetClsName:String = Type.getClassName(Type.getClass(targetCls));
		for (t in runQueue)
		{
			final taskClsName:String = Type.getClassName(Type.getClass(t));
			if (taskClsName != targetClsName)
			{
				#if SCHEDULER_LOG
				trace('[refracta/scheduler] skipping $taskClsName because we are looking for $targetClsName.');
				#end
				continue;
			}

			final taskDelegateData:ScheduledDelegateWithData<T> = cast t;

			// ensure the single queued instance always has the most recent data.
			taskDelegateData.data = data;
			targetCls = null;
			targetClsName = null;
			return false;
		}

		enqueue(new ScheduledDelegateWithData<T>(task, data));
		return true;
	}

	private function queueTimedTasks()
	{
		if (timedTasks.length == 0)
			return;

		final currentTimeLocal:Float = currentTime;
		for (sd in timedTasks)
		{
			if (sd.executionTime > currentTimeLocal)
				continue;

			tasksToRemove.push(sd);

			if (sd.cancelled)
				continue;

			if (sd.repeatInterval == 0)
			{
				perUpdateTasks.push(sd);
				continue;
			}

			if (sd.repeatInterval > 0)
			{
				if (timedTasks.length > log_excessive_queue_length_interval)
					throw "Too many timed tasks are in the queue.";

				sd.setNextExecution(currentTimeLocal);
				tasksToSchedule.push(sd);
			}

			if (!sd.completed)
				enqueue(sd);
		}

		for (t in tasksToRemove)
			timedTasks.remove(t);

		tasksToRemove.resize(0);

		for (t in tasksToSchedule)
			timedTasks.addInPlace(t);

		tasksToSchedule.resize(0);
	}

	private function queuePerUpdateTasks()
	{
		if (perUpdateTasks.length == 0)
			return;

		var i:Int = 0;
		while (i < perUpdateTasks.length)
		{
			final task:ScheduledDelegate = perUpdateTasks[i];
			task.setNextExecution(null);
			if (task.cancelled)
			{
				// kinda a removeAt replacement for c#?
				perUpdateTasks.splice(i--, 1);
				continue;
			}

			enqueue(task);

			i++;
		}
	}

	private function getNextTask(task:Ref<Null<ScheduledDelegate>>):Bool
	{
		if (runQueue.length > 0)
		{
			task.set(runQueue.dequeue());
			return true;
		}

		task.set(null);
		return false;
	}

	private function enqueue(task:ScheduledDelegate)
	{
		runQueue.enqueue(task);
		#if SCHEDULER_LOG
		trace('[refracta/scheduler] queueing new ${Type.getClassName(Type.getClass(task))}');
		#end
		if (runQueue.length % log_excessive_queue_length_interval == 0)
			trace('[refracta/scheduler] the scheduler has ${runQueue.length} tasks pending.');
	}
}
