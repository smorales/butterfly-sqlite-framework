package butterfly.air.sqlite
{
	import flash.errors.SQLError;
	
	/**
	 * @author solano
	 * @playerversion AIR 2.0
	 */
	public class SQLiteLog
	{
		public var procName : String;
		public var query : String;
		public var castingClass : Class;
		public var sqlError : SQLError;
		private var parameters : Vector.<String>;

		public function SQLiteLog()
		{
			parameters = new Vector.<String>();
		}

		public function addParamter($key : String, $value : String) : void
		{
			parameters.push($key + ': ' + $value);
		}

		public function toString() : String
		{
			var str : String = '';
			str += '\n****************** SQLITE LOG ******************';

			if (sqlError) str += '\nERROR: ' + sqlError.details;
			str += '\nPROC NAME: ' + procName;
			str += '\n\nQUERY: ' + query;
			str += '\n\nCAST TO CLASS:' + castingClass;
			str += '\n\nPARAMETERS:';

			for each (var param : String in parameters)
			{
				str += '\n\t' + param;
			}

			str += '\n************************************************\n';

			return str;
		}

		public function printLog() : void
		{
			trace(this);
		}
	}
}
