package bindables;

/**
	A bindable carrying a mutually exclusive lease on another bindable.

	Can only be retrieved via `Bindable<T>.beginLease`.
**/
@:generic
class LeasedBindable<T> extends Bindable<T>
{
	private final source:Bindable<T>;
	private final valueBeforeLease:Null<T>;
	private final disabledBeforeLease:Bool;
	private final revertValueOnReturn:Bool = false;

	private var hasBeenReturned:Bool = false;

	// constructor is supposed to be internal.
	public function new(source:Bindable<T>, revertValueOnReturn:Bool = true, defaultValue:Null<T> = null)
	{
		super(defaultValue);

		bindTo(source);
		this.source = source ?? throw "Provided source is null.";

		if (revertValueOnReturn)
		{
			this.revertValueOnReturn = true;
			valueBeforeLease = value;
		}

		disabledBeforeLease = disabled;
		disabled = true;
	}

	// it should be called "return" but im not using pascal case so it throws by default
	public function ret():Bool
	{
		if (hasBeenReturned)
			return false;

		if (source == null)
			throw "Must return from original leased source";

		unbindAll();
		return true;
	}

	@:noCompletion
	override function set_value(value:T):T
	{
		if (source != null)
			checkValid();

		if (this.value == value)
			return this.value;

		setValue(this.value, value, true);
		return value;
	}

	@:noCompletion
	override function set_defaultValue(value:T):T
	{
		if (source != null)
			checkValid();

		if (this.defaultValue == value)
			return this.defaultValue;

		setDefaultValue(defaultValue, value, true);
		return value;
	}

	@:noCompletion
	override function set_disabled(state:Bool):Bool
	{
		if (source != null)
			checkValid();

		if (disabled == state)
			return disabled;

		setDisabled(state, true);
		return state;
	}

	override function unbindAllInternal()
	{
		if (source != null && !hasBeenReturned)
		{
			if (revertValueOnReturn)
				value = valueBeforeLease;

			disabled = disabledBeforeLease;

			source.endLease(this);
			hasBeenReturned = true;
		}

		super.unbindAllInternal();
	}

	// not the same as the og one
	override function createInstance():Bindable<T>
	{
		return new LeasedBindable<T>(null);
	}

	private function checkValid()
	{
		if (source != null && hasBeenReturned)
			throw "Cannot perform operations on a LeasedBindable that has been returned.";
	}
}
