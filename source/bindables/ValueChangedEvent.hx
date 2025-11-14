package bindables;

// https://github.com/ppy/osu-framework/blob/master/osu.Framework/Bindables/ValueChangedEvent.cs
// pretty much similar to a readonly struct

/**
	An event fired when a value changes, providing the old and new value for reference.
**/
typedef ValueChangedEvent<T> =
{
	/**
		The old value.
	**/
	var oldValue(default, null):T;

	/**
		The new (and current) value.
	**/
	var newValue(default, null):T;
};
