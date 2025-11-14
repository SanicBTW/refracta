package ds;

import core.Ref;
import haxe.ds.Vector;

// An attempt to port C#'s queue to Haxe
// https://github.com/dotnet/runtime/blob/5535e31a712343a63f5d7d796cd874e563e5ac14/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/Queue.cs

/**
	Represents a first-in, first-out collection of objects.

	Implemented as a circular buffer, so `Enqueue(T)` and `Dequeue` are typically `O(1)`.
**/
@:generic
@:allow(ds.QueueEnumerator)
class Queue<T>
{
	var array:Vector<T>; // we using a vector as an array since we have Vector.blit n shi yknow
	final _head:Ref<Int> = Ref.create(0); // creating a ref to keep track of the underlying value and being able to modify it thru the ref
	final _tail:Ref<Int> = Ref.create(0);
	var _size:Int = 0;
	var _version:Int = 0;

	public var length(get, null):Int;

	@:noCompletion
	private function get_length():Int
		return _size;

	public function new(initialCapacity:Int = 0)
	{
		if (initialCapacity < 0)
			throw "The initial capacity must be non-negative.";

		array = new Vector<T>(initialCapacity);
		_size = 0;
		_version = 0;
	}

	public function clear():Void
	{
		if (_size != 0)
		{
			array = new Vector<T>(0);
			_size = 0;
		}

		_head.set(0);
		_tail.set(0);
		_version++;
	}

	public function enqueue(item:T)
	{
		if (_size == array.length)
			grow(_size + 1);

		array.set(_tail, item);
		moveNext(_tail);

		_size++;
		_version++;
	}

	public function dequeue():T
	{
		if (_size == 0)
			throw "Empty queue.";

		final head:Int = _head;
		final removed:T = array[head];
		array.set(head, null);
		moveNext(_head);

		_size--;
		_version++;

		return removed;
	}

	// In C#, we pass a variable into the function which acts as an "out" letting us modify the value inside the scope of the function
	// we could use a workaround in Haxe using our Ref system but it gives a little bit of boilerplate to successfully fetch some data
	// instead we just return a null in case of being out of bounds, which is basically what the base trydequeue implementation does
	// https://github.com/dotnet/runtime/blob/5535e31a712343a63f5d7d796cd874e563e5ac14/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/Queue.cs#L215
	// we can always implement a special function that accepts a ref and call it a day but i dont believe Haxe peeps would use some C# syntax like that
	public function tryDequeue():Null<T>
		return _size == 0 ? null : dequeue();

	public function peek():T
	{
		if (_size == 0)
			throw "Empty queue.";

		return array[_head.deref()];
	}

	public function tryPeek():Null<T>
		return _size == 0 ? null : peek(); // same issue as trydequeue, read it

	// before cooking me please check
	// https://github.com/dotnet/runtime/blob/5535e31a712343a63f5d7d796cd874e563e5ac14/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/Queue.cs#L264
	public function contains(item:T):Bool
	{
		if (_size == 0)
			return false; // duh

		final vArray:Array<T> = array.toData();
		if (_head.deref() < _tail.deref())
			return vArray.slice(_head, _size).indexOf(item) >= 0;

		return vArray.slice(_head, vArray.length - _head.deref()).indexOf(item) >= 0 || vArray.slice(0, _tail).indexOf(item) >= 0;
	}

	public function toArray():Array<T>
	{
		if (_size == 0)
			return [];

		final copyVec:Vector<T> = new Vector<T>(_size);

		if (_head.deref() < _tail.deref())
		{
			Vector.blit(array, _head, copyVec, 0, _size);
		}
		else
		{
			Vector.blit(array, _head, copyVec, 0, array.length - _head.deref());
			Vector.blit(array, 0, copyVec, array.length - _head.deref(), _tail);
		}

		return copyVec.toArray();
	}

	public function iterator():Iterator<T>
		return new QueueEnumerator(this);

	private function setCapacity(capacity:Int)
	{
		var newVector:Vector<T> = new Vector<T>(capacity);
		if (_size > 0)
		{
			if (_head.deref() < _tail.deref())
				Vector.blit(array, _head, newVector, 0, _size);
			else
			{
				Vector.blit(array, _head, newVector, 0, array.length - _head.deref());
				Vector.blit(array, 0, newVector, array.length - _head.deref(), _tail);
			}
		}

		array = newVector;
		_head.set(0);
		_tail.set(_size == capacity ? 0 : _size);
		_version++;
	}

	// https://github.com/dotnet/runtime/blob/5535e31a712343a63f5d7d796cd874e563e5ac14/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/Queue.cs#L378
	// I honestly didn't want to port this but the queue seems to be growing constantly without any stop or resize, so this must be done
	// cant make them statics "A generic class can't have static fields" it has a point
	private final growFactor:Int = 2;
	private final minimumGrow:Int = 4;

	private function grow(capacity:Int)
	{
		var newCapacity:Int = growFactor * array.length;

		if (newCapacity > Math.POSITIVE_INFINITY)
			newCapacity = Std.int(Math.POSITIVE_INFINITY);

		newCapacity = Std.int(Math.max(newCapacity, array.length + minimumGrow));

		if (newCapacity < capacity)
			newCapacity = capacity;

		setCapacity(newCapacity);
	}

	private function moveNext(index:Ref<Int>)
	{
		var tmp:Int = index.deref() + 1;
		if (tmp == array.length)
			tmp = 0;

		index.set(tmp);
	}
}

@:generic
class QueueEnumerator<T>
{
	private final queue:Queue<T>;
	private final version:Int;

	private var index:Int; // -1 not started, -2 ended/disposed

	public function new(queue:Queue<T>)
	{
		this.queue = queue;
		version = queue._version;
		index = -1;
	}

	public function dispose()
	{
		index = -2;
	}

	public function hasNext():Bool
	{
		return (index != -2 && index != queue.length - 1);
	}

	public function next():T
	{
		if (version != queue._version)
			throw "Queue modified during iteration.";

		index++;

		if (index == queue.length)
		{
			index = -2;
			return null;
		}

		final capacity:Int = queue.length;

		var arrayIndex:Int = queue._head.deref() + index;
		if (arrayIndex >= capacity)
			arrayIndex -= capacity;

		return queue.array[arrayIndex];
	}
}
