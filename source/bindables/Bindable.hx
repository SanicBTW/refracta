package bindables;

import core.WeakRef;

// yeah uh they use events on C#, I'm sorry but I don't need an extra complex event system if I only need to SAVE callbacks
typedef EventCallback<T> = T->Void;

// this should be backtracked into an interface rather than a class
// TODO: remove the dead references from the list instead of just keeping them and looping over them
// if wanted to override any getter / setter it should be doable just by simply calling override private function get_<name> with the appropiate typing

@:generic
class Bindable<T>
{
	private var valueChanged:Array<EventCallback<ValueChangedEvent<T>>> = [];
	private var disabledChanged:Array<EventCallback<Bool>> = [];
	private var defaultChanged:Array<EventCallback<ValueChangedEvent<T>>> = [];

	private var _value:T;
	private var _defaultValue:T;

	private var _disabled:Bool;

	/**
		Whether this bindable has been disabled. When disabled, attempting to change the `value` will result in an `Exception`.
	**/
	public var disabled(get, set):Bool;

	@:noCompletion
	private function get_disabled():Bool
		return _disabled;

	@:noCompletion
	private function set_disabled(value:Bool):Bool
	{
		// if a lease is active, disabled can *only* be changed by that leased bindable.
		throwIfLeased();

		if (_disabled == value)
			return _disabled;

		setDisabled(value);
		return value;
	}

	private function setDisabled(value:Bool, bypassChecks:Bool = false, source:Null<Bindable<T>> = null)
	{
		if (!bypassChecks)
			throwIfLeased();

		_disabled = value;
		triggerDisabledChange(source ?? this, true, bypassChecks);
	}

	/**
		Check whether the current `value` is equal to `defaultValue`.
	**/
	public var isDefault(get, never):Bool;

	@:noCompletion
	private function get_isDefault():Bool
		return value == defaultValue;

	/**
		Revert the current `value` to the defined `defaultValue`.
	**/
	public function setDefault()
	{
		_value = _defaultValue;
	}

	/**
		The current value of this bindable.
	**/
	public var value(get, set):T;

	@:noCompletion
	private function get_value():T
		return _value;

	@:noCompletion
	private function set_value(newValue:T):T
	{
		// intentionally don't have throwIfLeased() here.
		// if the leased bindable decides to disable exclusive access (by setting Disabled = false) then anything will be able to write to Value.

		if (disabled)
			throw 'Can not set value to "${newValue}" as bindable is disabled.';

		if (value == newValue)
			return _value;

		setValue(_value, newValue);
		return newValue;
	}

	private function setValue(prevValue:T, newValue:T, bypassChecks:Bool = false, source:Null<Bindable<T>> = null)
	{
		_value = newValue;
		triggerValueChange(prevValue, source ?? this, true, bypassChecks);
	}

	// "unexpected keyword default" - not using pascal case on haxe too soo

	/**
		The default value of this bindable. Used when calling `setDefault` or querying `isDefault`.
	**/
	public var defaultValue(get, set):T;

	@:noCompletion
	private function get_defaultValue():T
		return _defaultValue;

	@:noCompletion
	private function set_defaultValue(newDefault:T):T
	{
		// intentionally don't have throwIfLeased() here.
		// if the leased bindable decides to disable exclusive access (by setting Disabled = false) then anything will be able to write to Default.

		if (disabled)
			throw 'Can not set default value to ${newDefault} as bindable is disabled.';

		if (defaultValue == newDefault)
			return defaultValue;

		setDefaultValue(defaultValue, newDefault);
		return newDefault;
	}

	private function setDefaultValue(prevValue:T, newValue:T, bypassChecks:Bool = false, source:Null<Bindable<T>> = null)
	{
		_defaultValue = newValue;
		triggerDefaultChange(prevValue, source ?? this, true, bypassChecks);
	}

	private var weakReferenceInstance:Null<WeakRef<Bindable<T>>> = null;

	private var weakReference(get, never):WeakRef<Bindable<T>>;

	// for good measure, to avoid having different behaviours between targets, the weakref here WONT be hard on cpp targets

	@:noCompletion
	private function get_weakReference():WeakRef<Bindable<T>>
		return weakReferenceInstance ??= new WeakRef<Bindable<T>>(this);

	/**
		Creates a new bindable instance initialised with a default value.
		@param defaultValue The initial and default value for this bindable.
	**/
	public function new(defaultValue:Null<T> = null)
	{
		_value = this.defaultValue = defaultValue;
	}

	// it should be a LockedWeakList, since the implementation of locks could potentially be different between platforms
	// I'm afraid I won't be implementing any of it for now
	private var bindings:Array<WeakRef<Bindable<T>>> = [];

	/**
		An alias of `bindTo` provided for use in object initializer scenarios.

		Passes the provided value as the foreign (more permanent) bindable.
	**/
	public var bindTarget(never, set):Bindable<T>;

	@:noCompletion
	private function set_bindTarget(target:Bindable<T>)
	{
		bindTo(target);
		return target;
	}

	/**
		Copies all values and value limitations of this bindable to another.
		@param them The target to copy to.
	**/
	public function copyTo(them:Bindable<T>)
	{
		them.value = value;
		them.defaultValue = defaultValue;
		them.disabled = disabled;
	}

	/**
		Binds this bindable to another such that bi-directional updates are propagated.

		This will adopt any values and value limitations of the bindable bound to.

		@param them The foreign bindable. This should always be the most permanent end of the bind.
		@throws "InvalidOperationException" Thrown when attempting to bind to an already bound object.
	**/
	public function bindTo(them:Bindable<T>)
	{
		if (this.bindings.contains(them.weakReference) == true)
			throw "An already bound bindable cannot be bound again.";

		them.copyTo(this);

		addWeakReference(them.weakReference);
		them.addWeakReference(weakReference);
	}

	/**
		Bind an action to `valueChanged` with the option of running the bound action once immediately.

		@param onChange The action to perform when `value` changes.
		@param runOnceImmediately Whether the action provided in `onChange` should be run once immediately.
	**/
	public function bindValueChanged(onChange:EventCallback<ValueChangedEvent<T>>, runOnceImmediately:Bool = false)
	{
		valueChanged.push(onChange);
		if (runOnceImmediately)
			onChange({oldValue: value, newValue: value});
	}

	/**
		Bind an action to `disabledChanged` with the option of running the bound action once immediately.

		@param The action to perform when `disabled` changes.
		@param runOnceImmediately Whether the action provided in `onChange` should be run once immediately.
	**/
	public function bindDisabledChanged(onChange:EventCallback<Bool>, runOnceImmediately:Bool = false)
	{
		disabledChanged.push(onChange);
		if (runOnceImmediately)
			onChange(disabled);
	}

	private function addWeakReference(weakReference:WeakRef<Bindable<T>>)
		bindings.push(weakReference);

	private function removeWeakReference(weakReference:WeakRef<Bindable<T>>)
		bindings.remove(weakReference);

	/**
		Raise `valueChanged` and `disabledChanged` once, without any changes actually occurring.

		This does not propagate to any outward bound bindables.
	**/
	public function triggerChange()
	{
		triggerValueChange(value, this, false);
		triggerDisabledChange(this, false);
	}

	private function triggerValueChange(previousValue:T, source:Bindable<T>, propagateToBindings:Bool = true, bypassChecks:Bool = false)
	{
		// check a bound bindable hasn't changed the value again (it will fire its own event)
		final beforePropagation:T = value;

		if (propagateToBindings)
		{
			for (b in bindings)
			{
				final bindable:Bindable<T> = b.deref();
				if (bindable == null || bindable == source)
					continue;

				bindable.setValue(previousValue, value, bypassChecks, this);
			}
		}

		if (beforePropagation == value)
			invokeCallbacks(valueChanged, {oldValue: previousValue, newValue: value});
	}

	private function triggerDefaultChange(previousValue:T, source:Bindable<T>, propagateToBindings:Bool = true, bypassChecks:Bool = false)
	{
		// check a bound bindable hasn't changed the value again (it will fire its own event)
		final beforePropagation:T = defaultValue;

		if (propagateToBindings)
		{
			for (b in bindings)
			{
				final bindable:Bindable<T> = b.deref();
				if (bindable == null || bindable == source)
					continue;

				bindable.setDefaultValue(previousValue, defaultValue, bypassChecks, this);
			}
		}

		if (beforePropagation == defaultValue)
			invokeCallbacks(defaultChanged, {oldValue: previousValue, newValue: defaultValue});
	}

	private function triggerDisabledChange(source:Bindable<T>, propagateToBindings:Bool = true, bypassChecks:Bool = false)
	{
		// check a bound bindable hasn't changed the value again (it will fire its own event)
		final beforePropagation:Bool = disabled;

		if (propagateToBindings)
		{
			for (b in bindings)
			{
				final bindable:Bindable<T> = b.deref();
				if (bindable == null || bindable == source)
					continue;

				bindable.setDisabled(disabled, bypassChecks, this);
			}
		}

		if (beforePropagation == disabled)
			invokeCallbacks(disabledChanged, disabled);
	}

	/**
		Unbinds any actions bound to the value changed events.
	**/
	public function unbindEvents()
	{
		valueChanged.resize(0);
		defaultChanged.resize(0);
		disabledChanged.resize(0);
	}

	/**
		Remove all bound `Bindable<T>`s via `getBoundCopy` or `bindTo`.
	**/
	public function unbindBindings()
	{
		for (b in bindings)
		{
			final bindable:Null<Bindable<T>> = b.deref();
			if (bindable == null)
				continue;
			unbindFrom(bindable);
		}
	}

	/**
		Calls `unbindEvents` and `unbindBindings`.

		Also returns any active lease.
	**/
	public function unbindAll()
	{
		unbindAllInternal();
	}

	private function unbindAllInternal()
	{
		if (isLeased)
			leasedBindable.ret();

		unbindEvents();
		unbindBindings();
	}

	public function unbindFrom(them:Bindable<T>)
	{
		removeWeakReference(them.weakReference);
		them.removeWeakReference(weakReference);
	}

	/**
		Create an unbound clone of this bindable.
	**/
	public function getUnboundCopy():Bindable<T>
	{
		final newBindable:Bindable<T> = createInstance();
		copyTo(newBindable);
		return newBindable;
	}

	/**
		Retrieve a new bindable instance weakly bound to the configuration backing.
		If you are further binding to events of a bindable retrieved using this method, ensure to hold
		a local reference.

		@returns A weakly bound copy of the specified bindable.
		@throws "InvalidOperationException" Thrown when attempting to instantiate a copy bindable that's not matching the original's type.
	**/
	public function getBoundCopy():Bindable<T>
	{
		final newBindable:Bindable<T> = createInstance();
		newBindable.bindTo(this);
		return newBindable;
	}

	// please override this function on any class that extends bindable

	/**
		Creates a new instance of this `Bindable<T>` for use in `getBoundCopy`.

		The returned instance must have match the most derived type of the bindable class this method is implemented on.
	**/
	private function createInstance():Bindable<T>
	{
		return new Bindable<T>();
	}

	private var leasedBindable:Null<LeasedBindable<T>> = null;

	private var isLeased(get, never):Bool;

	@:noCompletion
	private function get_isLeased():Bool
		return leasedBindable != null;

	/**
		Takes out a mutually exclusive lease on this bindable.

		During a lease, the bindable will be set to `disabled`, but changes can still be applied via the `LeasedBindable<T>` returned by this call.

		You should end a lease by calling `LeasedBindable<T>.ret` when done.

		@param revertValueOnReturn Whether the `value` when `beginLease` was called should be restored when the lease ends.
		@returns A bindable with a lease.
	**/
	public function beginLease(revertValueOnReturn:Bool):LeasedBindable<T>
	{
		if (checkForLease(this))
			throw "Attempted to lease a bindable that is already in a leased state.";

		return leasedBindable = new LeasedBindable<T>(this, revertValueOnReturn);
	}

	// NOT TESTED!
	private function checkForLease(source:Bindable<T>):Bool
	{
		if (isLeased)
			return true;

		if (bindings.length <= 0)
			return false;

		var bin:Int = 0;

		for (b in bindings)
		{
			final bindable:Bindable<T> = b.deref();
			if (bindable == null)
				continue;

			if (bindable != source)
			{
				final res:Bool = bindable.checkForLease(this);
				bin |= res ? 1 : 0; // so basically, 1 for true and 0 for false? uh idk what i did here
			}
		}

		trace(bin);
		return bin == 1;
	}

	/**
		Called internally by a `LeasedBindable<T>` to end a lease.

		@param returnedBindable The `LeasedBindable<T>` that was provided as a return of a `beginLease` call.
	**/
	private function endLease(returnedBindable:LeasedBindable<T>)
	{
		if (!isLeased)
			throw "Attempted to end a lease without beginning one.";

		if (returnedBindable != leasedBindable)
			throw "Attempted to end a lease but returned a different bindable to the one used to start the lease.";

		leasedBindable = null;
	}

	private function throwIfLeased()
	{
		if (isLeased)
			throw "Cannot perform this operation on a Bindable that is currently in a leased state.";
	}

	private function invokeCallbacks<E>(origin:Array<EventCallback<E>>, value:E)
	{
		for (c in origin)
			c(value);
	}
}
