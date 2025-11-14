package extensions;

// this code is fresh out of the box (not reworked or anything, just copied from my projects lol)
class ArrayExtensions
{
	// https://github.com/dotnet/runtime/blob/main/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/ArraySortHelper.cs#L333
	@:generic
	public static function binarySearch<T>(array:Array<T>, index:Int, length:Int, value:T):Int
	{
		var lo:Int = index;
		var hi:Int = index + length - 1;

		while (lo <= hi)
		{
			var i:Int = lo + ((hi - lo) >> 1);
			var order:Int;
			if (array[i] == null)
				order = (value == null) ? 0 : -1;
			else
				order = Reflect.compare(array[i], value); // have to implement the default comparer?

			if (order == 0)
				return i;

			if (order < 0)
				lo = i + 1;
			else
				hi = i - 1;
		}

		return ~lo;
	}

	public static function binarySearchQuick<T>(array:Array<T>, value:T):Int
		return binarySearch(array, 0, array.length, value);

	// https://github.com/ppy/osu-framework/blob/master/osu.Framework/Extensions/ExtensionMethods.cs#L34
	public static function addInPlace<T>(array:Array<T>, item:T):Int
	{
		var index:Int = binarySearchQuick(array, item);
		if (index < 0)
			index = ~index;
		array.insert(index, item);
		return index;
	}
}
