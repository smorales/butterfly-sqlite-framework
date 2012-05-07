package butterfly.air.sqlite {
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	/**
	 * @author Solano Morales
	 */
	public class SQLiteModelTypeInfos
	{
		private static var COLLECTION : Object = {};
		
		public var primaryKeyName : String;
		public var findLastClause : String;
		public var findFirstClause : String;
		public var xmlDefinition : XML;
		public var fullQualifiedClassName : String;
		public var modelClass : Class;
		public var tableName : String;
		public var vectorClass : Class;
		public var arrayCollectionClass : Class;
		public var columnTypes:Object;
		
		public static function getModelType($model:SQLiteModel) : SQLiteModelTypeInfos
		{
			var fullQualifiedClassName:String = getQualifiedClassName($model);
			
			if (COLLECTION[fullQualifiedClassName]) 
				return COLLECTION[fullQualifiedClassName];
			
			
			var modelType:SQLiteModelTypeInfos = new SQLiteModelTypeInfos();
			modelType.xmlDefinition = describeType($model);
			modelType.fullQualifiedClassName = getQualifiedClassName($model);
			modelType.vectorClass = getDefinitionByName("__AS3__.vec::Vector.<"+fullQualifiedClassName+">") as Class;
			
			var cName:String = fullQualifiedClassName;
			modelType.modelClass = getDefinitionByName( cName.indexOf('::') == -1 ? cName : cName.split("::").join('.') ) as Class;
			modelType.tableName = cName.indexOf('::') == -1 ? cName : cName.split("::")[1];
			
			try{modelType.arrayCollectionClass = getDefinitionByName("mx.collections.ArrayCollection") as Class;}
			catch(e:Error){}
			
			modelType.columnTypes = {};
			
			var columns:Vector.<SQLiteColumn> = SQLiteTable.getTable($model).columns;
			for each (var col : SQLiteColumn in columns) 
			{
				if(col.primaryKey) 
				{
					modelType.primaryKeyName = col.name;
					if(col.dataTypeClassName == "int")
					{
						modelType.findLastClause = modelType.primaryKeyName+"=(SELECT max("+modelType.primaryKeyName+") FROM "+col.table.tableName+")";
						modelType.findFirstClause = modelType.primaryKeyName+"=(SELECT min("+modelType.primaryKeyName+") FROM "+col.table.tableName+")";
					}
				}
				
				modelType.columnTypes[col.name] = getDefinitionByName(col.dataTypeClassName) as Class;
			}
			
			COLLECTION[fullQualifiedClassName] = modelType;
			
			return modelType; 
		}
	}
}
