package;

import core.Cached.CachedGeneric;
import core.Ref;
import core.WeakRef;
import ds.Queue;
import ds.Stack;
#if cpp
import cpp.vm.Gc;
#end

// this currently serves as the testing entry point for the classes of the library
class App
{
	public static function main()
	{
		#if cpp
		Gc.enable(true);
		Gc.compact();
		#end

		final cock = new Ref<String>("hola");
		trace(cock);
		cock.set("adios");
		trace(cock);

		final cock2 = test();
		trace("Got WeakRef instance from function scope as " + cock2);

		#if cpp
		Gc.compact();
		Gc.run(true);
		#end

		trace("GC exec");

		final isNull:Bool = cock2.deref() == null;
		trace("Is null? " + isNull);
		trace("Value " + cock2);

		final cockTest:CachedGeneric<String> = new CachedGeneric<String>("hola");
		trace("Created cached generic: " + cockTest);

		trace("Is valid? " + cockTest.isValid);
		final invalidation = cockTest.invalidate();
		trace("Invalidated? " + invalidation);

		var reftest:Ref<Int> = new Ref<Int>(0);
		trace(reftest);
		reftest.set(1);
		trace(reftest);
		trace(reftest.deref());

		var queue = new Queue<String>();
		queue.enqueue("hola");
		queue.enqueue("hola1");
		queue.enqueue("hola2");
		queue.enqueue("hola3");
		for (cqe in queue)
		{
			trace(cqe);
		}

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

		try
		{
			cockTest.value = "adios";
		}
		catch (exc)
		{
			trace(exc);
		}
	}

	public static function test():WeakRef<String>
	{
		trace("Creating WeakRef inside a function");
		final cock2 = new WeakRef<String>("hola mundo");
		trace(cock2);
		return cock2;
	}
}
