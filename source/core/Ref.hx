package core;

// For some reason, the other ref impl is extremely weak, but when i say weak, its just literally not holding a reference
// inside the scope and its just returning null so uhh
#if cpp
import core.WeakRef;

@:generic
@:forward
abstract Ref<T>(WeakRef<T>)
{
	public inline function new(target:T)
	{
		this = new WeakRef(target, true);
	}

	@:from
	public inline static function create<T>(x:T):Ref<T>
	{
		return new Ref<T>(x);
	}

	@:to
	@:pure
	public inline function deref():T
	{
		return this.deref();
	}

	@:to
	public function toString():String
	{
		return "Ref(" + deref() + ")";
	}
}
#else
// Thanks to MKI for the code!!!

@:generic
@:structInit
@:allow(core.Ref)
private class RefData<T>
{
	private var data:T;
}

/**
	A "reference" to a variable, serving as a replacement to the "out" keyword from C#
**/
@:forward
@:generic
abstract Ref<T>(RefData<T>)
{
	@:pure
	public inline function new(x:T)
	{
		this = {
			data: x
		};
	}

	@:from
	public inline static function create<T>(x:T):Ref<T>
	{
		return new Ref<T>(x);
	}

	public inline function set(x:T):T
	{
		return this.data = x;
	}

	@:to
	@:pure
	public inline function deref():T
	{
		return this.data;
	}

	@:to
	public function toString():String
	{
		return "Ref(" + Std.string(this.data) + ")";
	}
}
#end
