package butterfly.air.sqlite 
{
	import flash.errors.SQLError;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	/**
	 * @author Solano Morales
	 * @playerversion AIR 2.0
	 */
	public class SQLiteTable 
	{
		private static var TABLES : Vector.<SQLiteTable> = new Vector.<SQLiteTable>();
		private static var TABLE_CONSTRAINTS : Vector.<SQLiteTableConstraint> = new Vector.<SQLiteTableConstraint>();
		private static var storedDefinitions : Object = {};
		private static var tablesCollection : Vector.<SQLiteTable> = new Vector.<SQLiteTable>();
		private var _xmlDescription : XML;
		private var _fullQualifiedClassName : String;
		private var _className : String;
		private var _queryCreateTable : String;
		private var _queryReplaceInto : String;
		private var _tableClass : Class;
		private var _querySelect : String;
		private var _columns : Vector.<SQLiteColumn>;
		private var _tableConstraints : Vector.<SQLiteTableConstraint>;
		private var sqlite : SQLite;
		
		public static function initTable($model:*, $sqlite:SQLite) : SQLiteTable
		{
			var qn:String = getQualifiedClassName($model);			
			var table:SQLiteTable = new SQLiteTable($model, $sqlite);
			storedDefinitions[qn] = table;
			tablesCollection.push(table);
			
			return table;
		}
		public static function getTable($model:*) : SQLiteTable
		{
			var qn:String = getQualifiedClassName($model);
			var table:SQLiteTable;
			
			if(storedDefinitions[qn] != null)
			{
				table = storedDefinitions[qn];
			}
			else
			{
				throw new SQLError("", "", "Table for model "+qn+" not found!" +
											"Make sure that the table was initialized " +
											"with mySQLiteInstance.initTable(MyModelClass).");
			}
			
			return table;			 
		}
		
		public function SQLiteTable($model:*, $sqlite:SQLite) 
		{
			sqlite = $sqlite;
			TABLES.push(this);
			
			_xmlDescription = describeType($model);
			
			var cName:String = String(_xmlDescription.@name);
			_className = cName.indexOf('::') == -1 ? cName : cName.split("::")[1];
			_fullQualifiedClassName = cName.indexOf('::') == -1 ? cName : cName.split("::").join('.');
			
			_tableClass = $model is Class ? $model : getQualifiedClassName($model) as Class;
			
			parseTableConstraints();	// 1
			parseColumns();				// 2, columns get infos about foreignkeys which are parsed in the previous method
			buildCreateQueryString();
			buildInsertQuery();
			buildSelectQuery();
			checkTableRelations();
		}

		private static function checkTableRelations() : void 
		{
			for each (var table : SQLiteTable in TABLES) 
			{
				for each (var constraint : SQLiteTableConstraint in table._tableConstraints) 
				{
					if(constraint.constraintType == SQLiteTableConstraint.FOREIGN_KEY)
					{
						var childKeys:Vector.<String> = constraint.childKeysCollection;
						for(var i:int=0; i<childKeys.length; i++) 
						{
							var childKey:String = childKeys[i];
							var parentKey:String = constraint.parentKeysCollection[i];
							var parentTableName:String = constraint.parentTable;
							var parentColumn:SQLiteColumn = SQLiteColumn.COLUMNS[table.sqlite.path+"_"+parentTableName+"_"+parentKey];
							
							
							if(parentColumn == null) continue;
							
							var parentTable:SQLiteTable = parentColumn.table;
							
							var childColumn:SQLiteColumn = SQLiteColumn.COLUMNS[table.sqlite.path+"_"+constraint.table.name+"_"+childKey];
							
							//find holder variable and present each other
							for each (var holderColumn : SQLiteColumn in parentTable._columns) 
							{
								if(holderColumn.relatedTableFK == childKey)
								{
									holderColumn.ownersPrimaryKey = parentKey;
									
									childColumn.parentColumn = parentColumn;
									childColumn.holderColumn = holderColumn;
									parentColumn.childColumn = childColumn;
									holderColumn.childColumn = childColumn;
									holderColumn.parentColumn = parentColumn;
								}
							}
						}
					}
				}
			}
		}
		
		
		internal static function getTableClassByName($className:String) : Class
		{
			for each (var table : SQLiteTable in tablesCollection) 
			{
				if(table.tableName.toLowerCase() == $className.toLowerCase()) return table.tableClass; 
			}
			
			return null;
		}
		
		internal static function getExternalTables($obj:*) : Vector.<SQLiteTableRelation>
		{
			var parentTable:SQLiteTable = getTable($obj);
			var tableRelations:Vector.<SQLiteTableRelation> = new Vector.<SQLiteTableRelation>();
			
			for each (var holderCol : SQLiteColumn in parentTable._columns) 
			{
				if(holderCol.relatedTableName!=null)
				{
					var relation:SQLiteTableRelation = new SQLiteTableRelation();
					relation.holderColumn = holderCol;
					relation.columnName = holderCol.name;
					relation.foreignKey = holderCol.relatedTableFK;
					relation.parentKey = holderCol.parentColumn.name;
					relation.tableName = holderCol.relatedTableName;
					relation.tableClass = getTableClassByName(holderCol.relatedTableName);
					tableRelations.push(relation);
				}
			}
			
			return tableRelations;
		}
		
		
		private function buildSelectQuery() : void 
		{
			var colNames:Vector.<String> = new Vector.<String>();
			for each (var column : SQLiteColumn in _columns) 
			{
				if(column.relatedTableName == null) colNames.push(" "+column.name);
			}
			
			_querySelect = "select "+colNames+" from "+tableName;
//			_querySelect = "select "+_columns+" from "+tableName;
		}

		private function buildInsertQuery() : void 
		{
			var colNames:Vector.<String> = new Vector.<String>();
			var colValues:Vector.<String> = new Vector.<String>();
			for each (var column : SQLiteColumn in _columns) 
			{
				if(column.relatedTableName == null)
				{
					colNames.push(" "+column.name);
					colValues.push(" @"+column.name);
				}
			}
			
			_queryReplaceInto = "REPLACE INTO "+tableName+" ("+colNames+" ) values ("+colValues+" )";
		}
		
		private function parseTableConstraints() : void 
		{
			_tableConstraints = new Vector.<SQLiteTableConstraint>();
			
			// parse PRIMARY KEY, UNIQUE and CHECK
			for each (var meta : XML in _xmlDescription.factory.metadata) 
			{
				var tableConstraint : SQLiteTableConstraint = null;
				var metaName:String = String(meta.@name).toLowerCase();
				var arg : XML = null;
				
				if(metaName == "primarykey") 
				{
					for each (arg in meta.arg) 
					{
						if(arg.@key == "columns") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.PRIMARY_KEY, this);
							tableConstraint.columns = arg.@value;
						}						
						if(arg.@key == "onConflict") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.PRIMARY_KEY, this);
							tableConstraint.onConflict = arg.@value;
						}						
					}
				}
				if(metaName == "foreignkey") 
				{
					for each (arg in meta.arg) 
					{
						if(arg.@key == "parentTable") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.FOREIGN_KEY, this);
							tableConstraint.parentTable = arg.@value;
						}						
						if(arg.@key == "parentKeys") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.FOREIGN_KEY, this);
							tableConstraint.parentKeys = arg.@value;
						}						
						if(arg.@key == "childKeys") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.FOREIGN_KEY, this);
							tableConstraint.childKeys = arg.@value;
						}						
						if(arg.@key == "onUpdate") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.FOREIGN_KEY, this);
							tableConstraint.onUpdate = arg.@value;
						}						
						if(arg.@key == "onDelete") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.FOREIGN_KEY, this);
							tableConstraint.onDelete = arg.@value;
						}						
					}
				}
				else if(metaName == "unique") 
				{
					for each (arg in meta.arg) 
					{
						if(arg.@key == "columns") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.UNIQUE, this);
							tableConstraint.columns = arg.@value;
						}
						if(arg.@key == "onConflict") 
						{
							if(tableConstraint==null) tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.UNIQUE, this);
							tableConstraint.onConflict = arg.@value;
						}						
					}
				}
				else if(metaName == "check") 
				{
					for each (arg in meta.arg) 
					{
						if(arg.@key == "expression") 
						{
							tableConstraint = new SQLiteTableConstraint(SQLiteTableConstraint.CHECK, this);
							tableConstraint.expression = arg.@value;
						}						
					}
				}
				
				if(tableConstraint!=null) 
				{
					_tableConstraints.push(tableConstraint);
					TABLE_CONSTRAINTS.push(tableConstraint);
				}
			}
		}
		
		private function parseColumns() : void 
		{
			_columns = new Vector.<SQLiteColumn>();
			for each (var node : XML in _xmlDescription..accessor) 
			{
				if (node.@access == "readwrite")
				{
					var column:SQLiteColumn = new SQLiteColumn(node, sqlite, this);
					_columns.push(column);
				}
			}
		}
		
		private function buildCreateQueryString() : void 
		{
			var colDef:Vector.<String> = new Vector.<String>();	
			for each (var col:SQLiteColumn in _columns) 		
			{
				colDef.push(col.definition);
			}
			_queryCreateTable = "CREATE TABLE IF NOT EXISTS "+tableName+" ( "+colDef + (_tableConstraints.length>0 ? ","+_tableConstraints : "") + " )";
//			trace('tblQuery: ' + (_queryCreateTable));
		}
		
		
		/**
		 * @return 	The column which is defined as primary key and is type od INTEGER.
		 * 			The value may be <code>NULL</code> if the table doesn't have an integer primary key.
		 */
		public function getPrimaryKeyColumn() : SQLiteColumn
		{
			for each (var col : SQLiteColumn in _columns) 
			{
				if(col.primaryKey && col.dbDataType == SQLiteColumnType.INTEGER) return col;
			}
			return null;
		}
		
		public function get tableClass() : Class
		{
			return _tableClass;
		}
		
		public function get querySelect() : String
		{
			return _querySelect;
		}
		
		public function get queryCreateTable() : String
		{
			return _queryCreateTable;
		}
		
		public function get queryReplaceInto() : String
		{
			return _queryReplaceInto;
		}
		
		public function get xmlDescription() : XML 
		{
			return _xmlDescription;
		}
		
		public function get name() : String 
		{
			return _className;
		}
		public function get tableName() : String 
		{
			return _className;
		}
		
		public function get className() : String 
		{
			return _className;
		}

		public function get fullQualifiedClassName() : String 
		{
			return _fullQualifiedClassName;
		}
		
		public function get columns() : Vector.<SQLiteColumn> {
			return _columns;
		}
		
		public function toString() : String
		{
			return "SQLiteTable [" + tableName + "]";
		}

	}
}





























































