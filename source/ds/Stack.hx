package ds;

@:generic
@:allow(ds.StackEnumerator)
class Stack<T>
{
	var array:Array<T>;
	var _size:Int;
	var _version:Int;

	public var length(get, null):Int;

	@:noCompletion
	private function get_length():Int
		return _size;

	public function new(?capacity:Int = 0)
	{
		if (capacity < 0)
			throw "Capacity must be non-negative.";

		array = new Array<T>();
		if (capacity > 0)
			array.resize(capacity);

		_size = 0;
		_version = 0;
	}

	public function push(item:T):Void
	{
		array.insert(_size++, item);
		_version++;
	}

	public function pop():T
	{
		if (_size == 0)
			throw "Stack is empty.";

		_version++;
		_size--;
		return array.pop();
	}

	public function tryPop():Null<T>
	{
		if (_size == 0)
			return null;

		_version++;
		_size--;
		return array.pop();
	}

	public function peek():T
	{
		if (_size == 0)
			throw "Stack is empty.";

		return array[_size - 1];
	}

	public function tryPeek():Null<T>
		return (_size > 0) ? array[_size - 1] : null;

	public function clear():Void
	{
		array = [];
		_size = 0;
		_version++;
	}

	public function contains(item:T):Bool
		return _size != 0 && array.lastIndexOf(item, _size - 1) != -1;

	public function toArray():Array<T>
	{
		// make a copy since array.reverse modifies the array and we dont want to modify the current one
		var stackArray = array;
		array.reverse();
		return stackArray;
	}

	public function iterator():Iterator<T>
		return new StackEnumerator(this);
}

@:generic
class StackEnumerator<T>
{
	private final stack:Stack<T>;
	private final version:Int;

	private var index:Int = -1;

	public function new(stack:Stack<T>)
	{
		this.stack = stack;
		version = stack._version;
		index = stack.length - 1;
	}

	public function hasNext():Bool
		return index >= 0;

	public function next():T
	{
		if (version != stack._version)
			throw "Stack modified during iteration.";

		return stack.array[index--];
	}
}
