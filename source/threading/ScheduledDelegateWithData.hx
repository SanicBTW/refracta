package threading;

// https://github.com/ppy/osu-framework/blob/0c8bac9b65bbbbb5e1f2f2b5ea4bed59baa4b620/osu.Framework/Threading/ScheduledDelegateWithData.cs
// honestly i dont know if i should do generic on here since the data is expected to be of some type but... for the sake of safety ill do it
@:generic
@:allow(threading.Scheduler)
class ScheduledDelegateWithData<T> extends ScheduledDelegate
{
	private var genTask:T->Void;

	public var data:T;

	public function new(task:T->Void, data:T, executionTime:Float = 0, repeatInterval:Float = -1)
	{
		super(null, executionTime, repeatInterval);

		genTask = task;
		this.data = data;
	}

	override function invokeTask()
	{
		if (genTask == null)
			return;

		genTask(data);
	}
}
