package butterfly.air.sqlite {
	/**
	 * @author Solano Morales
	 * @playerversion AIR 2.0
	 */
	public class SQLiteColumnType 
	{
		public static const BOOL:String = "BOOL";
		public static const DATETIME:String = "DATETIME";
		public static const INTEGER:String = "INTEGER";
		public static const REAL:String = "REAL";
		public static const TEXT:String = "TEXT";
		public static const XML:String = "XML";
		public static const XMLLIST:String = "XMLLIST";
		public static const BLOB:String = "BLOB";
		public static const OBJECT:String = "OBJECT";
		
		public static function getDataType($type:String) : String
		{
			var type:String;
			switch($type)
			{
				case 'Boolean':
					type = BOOL;
					break;
				case 'Date':
					type = DATETIME;
					break;
				case 'int':
					type = INTEGER;
					break;
				case 'Number':
					type = REAL;
					break;
				case 'String':
					type = TEXT;
					break;
				case 'XML':
					type = XML;
					break;
				case 'XMLList':
					type = XMLLIST;
					break;
				case 'flash.utils::ByteArray':
					type = BLOB;
					break;
				default:
					type = OBJECT;
			}
			
			return type;
		}
	}
}
