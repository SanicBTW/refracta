package timing;

// an attempt to port over osu!framework clock system
interface IClock
{
	var currentTime(get, never):Float;
	var rate(get, never):Float;
	var running(get, never):Bool;
}
