package butterfly.air.sqlite 
{
	import mx.collections.ArrayCollection;

	import flash.data.SQLResult;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	
	/**
	 * @author Solano Morales
	 */
	public class SQLiteModel 
	{
		private var _sqlite : SQLite;
		private var tableName : String;
		private var myClass : Class;
		private var xmlDefinition : XML;
		private var _successHandler:Function;
		private var _errorHandler : Function;
		private var countRelatedContent : int;
		private var loadClause : String;
		private var resultForFindAll : ArrayCollection;
		private var countModels : int;
		
		
		
		public function SQLiteModel() 
		{
			getModelInfos(this);
		}
		
		private static function getModelInfos($model:SQLiteModel) : void
		{
			$model.xmlDefinition = describeType($model);
			var cName:String = getQualifiedClassName($model);
			$model.myClass = getDefinitionByName( cName.indexOf('::') == -1 ? cName : cName.split("::").join('.') ) as Class;
			$model.tableName = cName.indexOf('::') == -1 ? cName : cName.split("::")[1];
		}
		
		private function internalErrorHandler($log:SQLiteLog) : void
		{
			if (_errorHandler != null) _errorHandler($log);
		}
		
		
		/*
		 * LOAD/SELECT
		 */
		public function find($whereClause : String, $successHandler : Function = null, $errorHandler : Function = null) : void
		{
			if(_sqlite==null) 
			{
				_sqlite = SQLite.getUniqueSQLite();
				if(_sqlite == null) throw new SQLiteError("Please define a SQLite instance before you load the model.");
			}
			
			if($successHandler != null) successHandler = $successHandler;
			if($errorHandler != null) errorHandler = $errorHandler;
			
			_sqlite.errorHandler = internalErrorHandler;
			_sqlite.successHandler = onModelLoad;
			_sqlite.load(this, $whereClause);
		}
		
		public function findAll($successHandler : Function = null, $errorHandler : Function = null) : void
		{
			loadClause = "all";
			find("", $successHandler, $errorHandler);
		}
		
		public function findFirst($successHandler : Function = null, $errorHandler : Function = null) : void
		{
			loadClause = "first";
			find("", $successHandler, $errorHandler);
		}
		
		public function findLast($successHandler : Function = null, $errorHandler : Function = null) : void
		{
			loadClause = "last";
			find("", $successHandler, $errorHandler);
		}
		
		internal function onModelLoad($result:ArrayCollection) : void
		{
			if ($result.length == 0) 
			{
				_successHandler(null);
				_successHandler = null;
				return;
			}
			
			if(loadClause=="all") 
			{
				resultForFindAll = $result;
				loadModelContents();				
			}
			
			mapValues($result);
			loadRelatedTables();
			
//			if(loadClause=="all")
//			{
//				callSuccessHandler($result);
//				return;
//			}
		}

		private function loadModelContents() : void 
		{
			countModels = resultForFindAll.length;
			for each (var model : SQLiteModel in resultForFindAll) 
			{
				if(model)
				{
					model.successHandler = onLoadedModelContent;
					model.loadRelatedTables();
				}
			}
		}

		private function onLoadedModelContent($model:SQLiteModel) : void 
		{
			if(--countModels==0)
			{
				callSuccessHandler(resultForFindAll);
			}
		}
		
		public function loadRelatedTables() : void
		{
			var childTables:Vector.<SQLiteTableRelation> = SQLiteTable.getExternalTables(this);
			countRelatedContent = childTables.length;
			for each (var childTable : SQLiteTableRelation in childTables) 
			{
				childTable.load(this, _sqlite);
			}
			
			if(countRelatedContent==0)
			{
				callSuccessHandler( loadClause=="all" ? resultForFindAll : this);
			}						
		}
		
		internal function onLoadedRelatedData($relation:SQLiteTableRelation) : void
		{
			if ($relation.holderColumn.isArrayCollection )
			{
				this[$relation.columnName] = $relation.data;
			}
			else if($relation.holderColumn.isVector)
			{
				var clazz:Class = getDefinitionByName($relation.holderColumn.dataTypeClassName) as Class;
				this[$relation.columnName] = clazz($relation.data.source);					
			}
			else if($relation.holderColumn.isArray)
			{
				this[$relation.columnName] = $relation.data.source;
			}
			else if($relation.data && $relation.data.length>0)
			{
				var d:* = $relation.data[0];
				this[$relation.columnName] = d;
			}
			
			//load now related tables
			if($relation.data && $relation.data.length>0 && $relation.data[0] is SQLiteModel)
			{
				for each (var m:SQLiteModel in $relation.data) 
					m.loadRelatedTables();
			}
			
			if(countRelatedContent>0) 
			{
				countRelatedContent--;
				if(countRelatedContent==0) 
				{
					callSuccessHandler( loadClause == "all" ? resultForFindAll : this);
				}
			}
			
			$relation.destroy();
		}
		
		
		
		/*
		 * SAVE/INSERT
		 */
		 
		public function save($successHandler:Function=null, $errorHandler:Function=null) : void
		{
			if(_sqlite==null) 
			{
				_sqlite = SQLite.getUniqueSQLite();
				if(_sqlite == null) throw new SQLiteError("Please define a SQLite instance before you save the model.");
			}
			
			if($successHandler != null) successHandler = $successHandler;
			if($errorHandler != null) errorHandler = $errorHandler;
			
			var startAndCommitTransaction:Boolean = !_sqlite.inTransaction;
			if(startAndCommitTransaction) 
				_sqlite.begin();
			
			_sqlite.errorHandler = internalErrorHandler;
			_sqlite.successHandler = onModelSave;
			_sqlite.save(this);
			if(startAndCommitTransaction) 
				_sqlite.commit();
				
			if(_successHandler!=null) 
			{
				_successHandler(this);
				_successHandler = null;
			}			
		}
		
		internal function onModelSave($stmt:SQLiteStatement, $result:SQLResult) : void 
		{
			var pk:SQLiteColumn = SQLiteTable.getTable(this).getPrimaryKeyColumn();
			if (pk) this[pk.name] = $result.lastInsertRowID;
			
			$stmt.destroy();
			
			updateRelatedTables();
		}
		
		public function updateRelatedTables() : void 
		{
			var columns:Vector.<SQLiteColumn> = getColumns();	
			
			for each (var col : SQLiteColumn in columns) 
			{
				if (col.relatedTableName != null) 
				{
					var column:* = this[col.name];
					var isModel:Boolean = column is SQLiteModel;
					if( column != null && ((col.isArrayCollection || col.isVector || col.isArray) || isModel))
					{
						if (isModel)
						{
							column[col.relatedTableFK] = this[col.ownersPrimaryKey];
							var m:SQLiteModel = SQLiteModel(column);
							m.setSQLite(_sqlite);
							m.save();
						}
						else
						{
							for each (var data : * in column) 
							{
								if (col.ownersPrimaryKey)
								{
									data[col.relatedTableFK] = this[col.ownersPrimaryKey];
									if(data is SQLiteModel)
									{
										SQLiteModel(data).save();
									}
									else
									{
										_sqlite.sqliteModel = this;
										_sqlite.successHandler = onUpdatedRelatedTables;
										_sqlite.save(data);								
									}								
								}
								else
								{
									trace("WARNING! ParentKey "+col.ownersPrimaryKey+" not found for column:"+col.name+" in table "+col.table.name);
									trace("Check if the model extends SQLiteModel or if metadata is right spelled.");
								}												
							}
						}
					}
				}
			}
		}

		internal function onUpdatedRelatedTables($stmt:SQLiteStatement, $result:SQLResult) : void 
		{
		}
		
		
		
		
		
		
		/**
		 * @return Returns key/value pairs for sqlitestatement. 
		 */
		internal function getInsertValues() : Object
		{
			var values:Object = {};
			var columns:Vector.<SQLiteColumn> = getColumns();
			
			for each (var col : SQLiteColumn in columns) 
			{
				if (col.relatedTableName == null)
				{
					var value:* = col.primaryKey && col.dbDataType == SQLiteColumnType.INTEGER && this[col.name]==0 ? null : this[col.name]; 
					values[col.name] = value;
				}
			}
			return values;
		}
		
		/**
		 * Assigns the loaded values to the instance. 
		 */
		private function mapValues($result : ArrayCollection) : void 
		{
			if ($result.length > 0)
			{
				var data:* = loadClause == "last" ? $result[$result.length-1] : $result[0];
				var columns:Vector.<SQLiteColumn> = getColumns();
				for each (var col : SQLiteColumn in columns) 
				{
					if(col.relatedTableName==null) 
					{
						this[col.name] = data[col.name];
					}
				}
			}
		}
		
		private function getColumns() : Vector.<SQLiteColumn>
		{
			return SQLiteTable.getTable(this).columns;
		}
		
		public function setSQLite(sqlite : SQLite) : void 
		{
			_sqlite = sqlite;
		}
		public function getSQLite() : SQLite
		{
			return _sqlite; 
		}

		public function set successHandler(successHandler : Function) : void {
			_successHandler = successHandler;
		}

		public function set errorHandler(errorHandler : Function) : void {
			_errorHandler = errorHandler;
		}
		
		private function callSuccessHandler($result:*) : void
		{
			if(_successHandler!=null)
			{
				 _successHandler($result);
				 _successHandler = null;
			}
		}
	}
}
