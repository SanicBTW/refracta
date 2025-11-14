package core;

// https://github.com/ppy/osu-framework/blob/master/osu.Framework/Caching/Cached.cs
// this is a port of my discord bot code which implements the cached object in another way
// the purpose of this class is to be the base of the rest of the classes cached that include the function invalidate
private class BaseCached
{
	// should be protected, meaning only the inheritance SHOULD be allowed to edit it
	private var _isValid:Bool = false;

	public var isValid(get, never):Bool;

	@:noCompletion
	private function get_isValid():Bool
		return _isValid;

	/**
		Invalidate the cache of this object.
		@returns true if we invalidated from a valid state
	**/
	public function invalidate():Bool
	{
		if (isValid)
		{
			_isValid = false;
			return true;
		}

		return false;
	}
}

class Cached extends BaseCached
{
	public function new(validated:Bool = true)
	{
		if (validated)
			validate();
	}

	public function validate()
	{
		_isValid = true;
	}
}

@:generic
class CachedGeneric<T> extends Cached
{
	private var _value:T;

	public var value(get, set):T;

	@:noCompletion
	private function get_value():T
	{
		if (!isValid)
			throw 'May not query the value of an invalid ${Type.getClassName(Type.getClass(this))}';

		return _value;
	}

	@:noCompletion
	private function set_value(newValue:T)
	{
		_value = newValue;
		validate();
		return _value;
	}

	public function new(?defaultValue:T)
	{
		super();

		// not calling set_value since it calls validate, we are already validated here
		if (defaultValue != null)
			_value = defaultValue;
	}
}
