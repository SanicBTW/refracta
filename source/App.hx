package;

import core.Cached.CachedGeneric;
import core.Ref;
import core.WeakRef;
import ds.Queue;
import ds.Stack;
import threading.ScheduledDelegate;
import threading.ScheduledDelegateWithData;
#if cpp
import cpp.vm.Gc;
#end

// this currently serves as the testing entry point for the classes of the library
class App
{
	public static function main()
	{
		new App();
	}

	public function new()
	{
		trace(" [refracte/tests] starting tests ");
		enableGc();

		strongRefTest();
		scopedWeakRefTest();
		cachedGenericTest();
		queueTest();
		stackTest();
		scheduledDelegateTest();
		scheduledDelegateWithDataTest();

		trace(" [refracta/tests] all tests run ");
	}

	private function enableGc()
	{
		#if cpp
		Gc.enable(true);
		Gc.compact();
		trace(" [refracta/gc] enabled cpp garbage collector ");
		return;
		#end

		trace(" [refracta/gc] platform doesn't expose the garbage collector ");
	}

	private function strongRefTest()
	{
		final cock = new Ref<String>("hola");
		trace(cock);
		cock.set("adios");
		trace(cock);
	}

	private function scopedWeakRefTest()
	{
		final cock2 = test();
		trace("Got WeakRef instance from function scope as " + cock2);

		runGc();

		final isNull:Bool = cock2.deref() == null;
		trace("Is null? " + isNull);
		trace("Value " + cock2);
	}

	private static function test():WeakRef<String>
	{
		trace("Creating WeakRef inside a function");
		final cock2 = new WeakRef<String>("hola mundo");
		trace(cock2);
		return cock2;
	}

	private function cachedGenericTest()
	{
		final cachedGen:CachedGeneric<String> = new CachedGeneric<String>("hola");
		trace("Created cached generic: " + cachedGen);

		trace("Is valid? " + cachedGen.isValid);
		final invalidation = cachedGen.invalidate();
		trace("Invalidated? " + invalidation);
	}

	private function queueTest()
	{
		var queue = new Queue<String>();
		queue.enqueue("hola");
		queue.enqueue("hola1");
		queue.enqueue("hola2");
		queue.enqueue("hola3");
		for (cqe in queue)
		{
			trace(cqe);
		}
	}

	private function stackTest()
	{
		var stack = new Stack<String>();
		stack.push("hola");
		stack.push("hola1");
		stack.push("hola2");

		var lastPop = stack.tryPop();
		trace(lastPop != null);
		trace(lastPop == "hola2");

		stack.push(lastPop);
		var stackArr = stack.toArray();
		for (str in stackArr)
			trace(str);

		for (str in stack)
			trace(str);
	}

	private function scheduledDelegateTest()
	{
		var scheduledNorm:ScheduledDelegate = new ScheduledDelegate(scheduledFunc);
		scheduledNorm.runTask();
		trace(scheduledNorm.completed);
		trace(scheduledNorm.state == COMPLETE);

		var scheduledThrwn:ScheduledDelegate = new ScheduledDelegate(scheduleThrow);
		scheduledThrwn.runTask();
		trace(scheduledThrwn.cancelled);
		trace(scheduledThrwn.state == CANCELLED);
	}

	private static function scheduledFunc()
	{
		trace("Hello from Scheduled Delegate!");
	}

	private static function scheduleThrow()
	{
		#if SCHEDULED_TASK_WRAP
		throw "Thrown inside a Scheduled Delegate";
		#else
		trace("This would crash the tests, not handled");
		#end
	}

	private function scheduledDelegateWithDataTest()
	{
		var scheduledDataNorm:ScheduledDelegateWithData<String> = new ScheduledDelegateWithData<String>(scheduleDataPrint,
			"Hello from a Scheduled Delegate with Data!");
		scheduledDataNorm.runTask();
		trace(scheduledDataNorm.completed);
		trace(scheduledDataNorm.state == COMPLETE);

		var scheduledDataThrwn:ScheduledDelegateWithData<String> = new ScheduledDelegateWithData<String>(scheduleDataThrow,
			"Thrown inside a Scheduled Delegate with Data");
		scheduledDataThrwn.runTask();
		trace(scheduledDataThrwn.cancelled);
		trace(scheduledDataThrwn.state == CANCELLED);
	}

	private static function scheduleDataPrint(str:String)
	{
		trace(str);
	}

	private static function scheduleDataThrow(str:String)
	{
		#if SCHEDULED_TASK_WRAP
		throw str;
		#else
		trace('This would crash the tests, not handled ($str)');
		#end
	}

	private function runGc()
	{
		#if cpp
		Gc.compact();
		Gc.run(true);
		trace(" [refracta/gc] garbage collect executed ");
		return;
		#end

		trace(" [refracta/gc] can't garbage collect manually on this platform ");
	}
}
