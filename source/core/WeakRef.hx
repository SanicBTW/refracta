package core;

#if js
// im sorry yall, i didnt want to resort to this thing but i cannot get over the constraint check set by the js lib (T:{})
// no need for comments if it aint accessed at all

@:native("WeakRef")
private extern class JSWeakRef<T>
{
	@:pure function new(target:T);
	@:pure function deref():Null<T>;
}
#end

// yah bro this is going to prod NOBODY tell me anything about it
// having a "Ref" and a "WeakRef" is kinda weird I know
// the reason why we are using Ref as the default is because the target doesnt have a WeakRef support, hence we just keep a strong reference to the target
private typedef _WeakRefImpl<T> = #if js JSWeakRef<T> #elseif cpp cpp.vm.WeakRef<T> #else Ref<T> #end;

// abstraction over the implementation, to share the same api

@:generic
abstract WeakRef<T>(_WeakRefImpl<T>)
{
	/**
		Creates a new WeakRef based on the underlying implementation of the platform.
		@param target the target to hold a WeakRef to.
		@param hard [CPP ONLY] if the target should be kept as a hard reference instead of being a weak one, acting like a basic Ref.
	**/
	@:pure
	public inline function new(target:T, hard:Bool = false)
	{
		#if js
		// uhh theres no way this actually worked bruh
		var obj = {value: target};
		this = new _WeakRefImpl(cast obj);
		#elseif cpp
		this = new _WeakRefImpl(target, hard);
		#else
		this = new _WeakRefImpl(target);
		#end
	}

	/**
		Returns this WeakRef target variable, null if the target variable has been garbage collected.
	**/
	@:to
	@:pure
	public inline function deref():Null<T>
	{
		#if cpp
		return this.get();
		#else
		// the JS and the default implementation uses deref
		// thanks to JS being an amazing language, i have to wrap the value or weakref value around and object
		// so it accepts it without whining, so we do this funky trick
		var ret:Dynamic = this.deref();
		return ret.value;
		#end
	}

	#if js
	/**
		Re-assign this WeakRef underlying implementation with the new target variable.
	**/
	#else
	/**
		Set the backing WeakRef value with the new target variable.
	**/
	#end
	public inline function set(x:T):T
	{
		#if cpp
		return this.set(x);
		#elseif js // i dont really know how it would be done on here so we just re-assign the weakref
		this = new _WeakRefImpl(x);
		return this.deref();
		#else // the default implementation is safe
		return this.set(x);
		#end
	}

	@:to
	public inline function toString():String
	{
		#if cpp
		return this.toString();
		#else
		return "WeakRef(" + deref() + ")";
		#end
	}
}
