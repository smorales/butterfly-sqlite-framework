package butterfly.air.sqlite 
{
	/**
	 * @author Solano Morales
	 * @playerversion AIR 2.0
	 */
	public class SQLiteColumnConstraint 
	{
		public static const PRIMARY_KEY:String = "PRIMARY KEY";
		public static const UNIQUE:String = "UNIQUE";
		public static const NOT_NULL:String = "NOT NULL";
		public static const CHECK:String = "CHECK";
		public static const DEFAULT:String = "DEFAULT";
		public static const COLLATE:String = "COLLATE";
		
		public var column : SQLiteColumn;		
		public var sortOrder:String = "";
		public var onConflict:String = "";
		public var defaultValue:* = "";
		public var collationName:String = "";
		public var expression:String = "";
		public var autoIncrement:Boolean = true;
		
		private var _constraint:String;
		
		
		public function SQLiteColumnConstraint($contraint:String) 
		{
			if(
				$contraint != SQLiteColumnConstraint.PRIMARY_KEY && 
				$contraint != SQLiteColumnConstraint.UNIQUE && 
				$contraint != SQLiteColumnConstraint.NOT_NULL && 
				$contraint != SQLiteColumnConstraint.CHECK && 
				$contraint != SQLiteColumnConstraint.DEFAULT && 
				$contraint != SQLiteColumnConstraint.COLLATE 
			)
			{
				throw new SQLiteColumnConstraintError("Please define a valid column constraint");
			}
			_constraint = $contraint;
		}
		
		public function get type() : String
		{
			return _constraint;
		}
		
		public function get constraint() : String
		{
			var c:String = " "+_constraint;
			var _conflictClause:String = onConflict=="" ? "" : " ON CONFLICT "+onConflict;
			var _sortOrder:String = sortOrder=="" ? "" : " "+sortOrder;
			var _defaultValue:String = defaultValue==null ? "" : !isDate(defaultValue) && isNaN(Number(defaultValue)) ? " '"+defaultValue+"'" : " ("+defaultValue+")";
			
			switch(_constraint)
			{
				case NOT_NULL:
					c += _conflictClause;
					break;
					
				case PRIMARY_KEY:
//					var autoInc:Boolean = column.dataType == SQLiteColumnType.INTEGER || column.dataType == SQLiteColumnType.REAL;
					c += _sortOrder + _conflictClause; // + (autoInc?"AUTOINCREMENT " : "");
					break;
					
				case UNIQUE:
					c += _conflictClause;
					break;
					
				case CHECK:
					//TODO test CHECK EXPRESSION like: salary NUMERIC CHECK (salary > 0)
					c += " ("+expression+")";
					break;
					
				case DEFAULT:
					c += _defaultValue;
					break;
					
				case COLLATE:
					c += collationName=="" ? "" : " "+collationName ;
					break;
					
				default:
			}
			
			return c;
		}

		private function isDate($value:*) : Boolean 
		{
			// metatag could be something like: datetime('now','localtime')
			if (( String($value).indexOf("date") != -1 || String($value).indexOf("time") != -1 ) )
			{
				return true;
			}			
			
			return $value=="CURRENT_TIME" || $value=="CURRENT_DATETIME" || $value=="CURRENT_DATE" || $value=="CURRENT_TIMESTAMP";
		}
		
		public function toString() : String
		{
			return constraint;
		}
	}
}
















































