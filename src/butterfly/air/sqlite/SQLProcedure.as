package butterfly.air.sqlite
{
	/**
	 * @author solano
	 * @playerversion AIR 2.0
	 */
	[Bindable]
	public class SQLProcedure
	{
		[PrimaryKey]
		public var name:String;
		public var query:String;
		
		public function toString() : String 
		{
			var str:String = 
			"********* PROCEDURE *******" +
			"\nname: "+name+"" +
			"\nquery<:" + query + ">" +
			"\n***************************";
			
			return str;
		}
		
		public function get primaryKeys() : Array
		{
			return ['id', 'name'];
		}
	}
}
