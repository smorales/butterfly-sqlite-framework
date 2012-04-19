package butterfly.air.sqlite
{
	import flash.events.Event;

	/**
	 * @author solano
	 * @playerversion AIR 2.0
	 */
	public class SQLiteEvent extends Event
	{
		public static const ERROR : String = "SQLITE_ERROR";
		public static const RESULT : String = "SQLITE_RESULT";
		public static const ON_LOADED_PROCEDURES : String = "SQLITE_ON_LOADED_PROCEDURES";
		
		public function SQLiteEvent(type : String, bubbles : Boolean = false, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
