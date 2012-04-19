package butterfly.air.sqlite 
{
	/**
	 * @author Solano Morales
	 * @playerversion AIR 2.0
	 */
	public class SQLiteTableConstraint 
	{
		public static const PRIMARY_KEY:String = "PRIMARY KEY";
		public static const UNIQUE:String = "UNIQUE";
		public static const CHECK : String = "CHECK";
		public static const FOREIGN_KEY : String = "FOREIGN KEY";
		
		private var _constraintType : String;

		public var columns:String = "";
		public var keys:String = "";
		public var onConflict:String = "";
		public var expression:String = "";
		public var parentTable:String = null;
		private var _parentKeys:String = null;
		private var _childKeys:String = null;
		public var onUpdate:String = null;
		public var onDelete : String = null;
		public var parentKeysCollection : Vector.<String>;
		public var childKeysCollection : Vector.<String>;
		public var table : SQLiteTable;
		
		public function SQLiteTableConstraint($constraintType:String, $table:SQLiteTable) 
		{
			table = $table;
			_constraintType = $constraintType;
		}

		public function get definition() : String
		{
			var def:String = "";
			var col:String;
			var conflictClause:String;
			
			switch(_constraintType)
			{
				case PRIMARY_KEY:
					col = columns != "" ? "("+columns+") " : "";
					conflictClause = onConflict!="" && col!="" ? "ON CONFLICT "+onConflict.toUpperCase() : "";
					def = PRIMARY_KEY + col + conflictClause;					
					break;
				
				case UNIQUE:
					col = columns != "" ? "("+columns+") " : "";
					conflictClause = onConflict != "" && col!="" ? "ON CONFLICT "+onConflict.toUpperCase() : "";
					def = UNIQUE + col + conflictClause;					
					break;
				
				case CHECK:
					def = expression=="" ? "" : CHECK + " (" + expression + ")";
					break;
				
				case FOREIGN_KEY:
					if(_parentKeys && parentTable && _childKeys)
					{
						var _onUpdate:String = onUpdate ? " ON UPDATE "+onUpdate : "";
						var _onDelete:String = onDelete ? " ON DELETE "+onDelete : "";
						def = FOREIGN_KEY + "(" + _childKeys + ") REFERENCES " + parentTable + " ("+_parentKeys + ") " + _onUpdate + _onDelete;
					}
					break;
				
				default:
			}
			
			return def;
		}
		
		public function toString() : String
		{
			return definition;
		}

		public function set parentKeys(parentKeys : String) : void {
			_parentKeys = parentKeys;
			parentKeysCollection = Vector.<String>(_parentKeys.replace(/ /g, "").split(","));
		}

		public function set childKeys(childKeys : String) : void {
			_childKeys = childKeys;
			childKeysCollection = Vector.<String>(_childKeys.replace(/ /g, "").split(","));
		}

		public function get constraintType() : String {
			return _constraintType;
		}
	}
}
