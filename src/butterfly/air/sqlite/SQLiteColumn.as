package butterfly.air.sqlite {
	/**
	 * @author Solano Morales
	 * @playerversion AIR 2.0
	 */
	public class SQLiteColumn 
	{
		public static var COLUMNS:Object = {};
		public var name:String;
		public var primaryKey:Boolean;
		public var autoIncrement:Boolean;
		public var dbDataType:String;
		public var dataTypeClassName:String;
		public var sortOrder:String = "";
		public var constraints:Vector.<SQLiteColumnConstraint>;
		public var table : SQLiteTable;
		public var relatedTableName:String;
		public var relatedTableFK:String;
		public var parentTable:String;
		public var parentKey:String;
		public var ownersPrimaryKey : String;
		public var childColumn:SQLiteColumn;
		public var holderColumn:SQLiteColumn;
		public var parentColumn:SQLiteColumn;
		public var tableClass:Class;
		
		private var sqlite : SQLite;
		
		public function SQLiteColumn($node:XML, $sqlite:SQLite, $table:SQLiteTable) 
		{
			constraints = new Vector.<SQLiteColumnConstraint>();
			sqlite = $sqlite;
			table = $table;
			dbDataType = SQLiteColumnType.getDataType($node.@type);
			dataTypeClassName = $node.@type;
			name = $node.@name;
			tableClass = table.tableClass;
			
			init($node..metadata);
			
			COLUMNS[sqlite.path+"_"+table.name+"_"+name] = this;
		}

		private function init($metaData:XMLList) : void 
		{
			for each (var meta : XML in $metaData)
			{
				var constraint:SQLiteColumnConstraint = null;
				var arg : XML;
				var metaName:String = String(meta.@name).toLowerCase();
				
				if(metaName == "relatedtable")
				{
					for each (arg in meta..arg)
					{
						if(arg.@key == "foreignKey" || arg.@key == "fk")
						{
							relatedTableFK = arg.@value;
						}								
						if(arg.@key == "table" || arg.@key == "model")
						{
							relatedTableName = arg.@value;
						}
					}
				}
				else if(metaName == "notnull") 
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.NOT_NULL );
					if(meta.arg.@key == "onConflict") 
					{
						constraint.onConflict = meta.arg.@value;
					}
				}
				else if(metaName == "primarykey")
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.PRIMARY_KEY );
					primaryKey = true;
					for each (arg in meta..arg)
					{
						if(arg.@key == "sortOrder") 
						{
							sortOrder = arg.@value;
							constraint.sortOrder = arg.@value;
						}
						if(arg.@key == "onConflict") constraint.onConflict = arg.@value;
						if(arg.@key == "autoIncrement") constraint.autoIncrement = String(arg.@value) == "true";
					}						
				}
				else if(metaName == "unique") 
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.UNIQUE );
					if(meta.arg.@key == "onConflict") constraint.onConflict = meta.arg.@value;
				}
				else if(metaName == "check") 
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.CHECK );
					if(meta.arg.@key == "expression") constraint.expression = meta.arg.@value;
				}
				else if(metaName == "default") 
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.DEFAULT );
					if(meta.arg.@key == "value") constraint.defaultValue = meta.arg.@value;
				}
				else if(metaName == "collate") 
				{
					constraint = new SQLiteColumnConstraint( SQLiteColumnConstraint.COLLATE );
					if(meta.arg.@key == "collationName") constraint.collationName = meta.arg.@value;
				}
				
				if(constraint!=null) 
				{
					constraint.column = this;
					constraints.push(constraint);
//							trace('column.definition: ' + (column.definition));
				}
			}
		}
		
		
		public function get foreignKey():Boolean
		{
			return parentTable && parentKey;
		}
		
		public function get definition() : String
		{
			var def:String = name + " " + dbDataType; 
			var defaultValue:String = " NULL";
			var additionalDef:String = " ";
			
			if(primaryKey && !(dbDataType == SQLiteColumnType.INTEGER || dbDataType == SQLiteColumnType.REAL) )
			{
				defaultValue = " NOT NULL";
			}

			var count:int = 0;
			for each (var c : SQLiteColumnConstraint in constraints) 
			{
				count++;
				
				if(c.type == SQLiteColumnConstraint.NOT_NULL) defaultValue = "";

				additionalDef += c.constraint;						
				if(count < constraints.length) additionalDef += " ";
			}				
			
			return def + defaultValue + additionalDef;
		}
		
		public function get pkDefinition() : String
		{
			return name + " " + sortOrder;
		}
		
		public function get isArray() : Boolean
		{
			return dataTypeClassName == "Array";
		}
		public function get isVector() : Boolean
		{
			return dataTypeClassName.indexOf("::Vector")!=-1;
		}
		public function get isArrayCollection() : Boolean
		{
			return dataTypeClassName == "mx.collections::ArrayCollection";
		}
		
		public function toString() : String
		{
			return name; 
		}
	}
}
