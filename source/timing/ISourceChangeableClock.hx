package timing;

interface ISourceChangeableClock extends IClock
{
	@:optional var source(get, never):IClock;

	function changeSource(source:IClock):Void;
}
