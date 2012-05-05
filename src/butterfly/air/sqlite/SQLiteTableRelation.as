package butterfly.air.sqlite 
{
	/**
	 * @author Solano Morales
	 * @author Solano Morales
	 * @private
	 */
	public class SQLiteTableRelation 
	{
		internal var tableName:String;
		internal var holderColumn:SQLiteColumn;
		internal var columnName:String;
		internal var foreignKey:String;
		internal var parentKey:String;
		internal var tableClass : Class;
		internal var data : Array;
		
		private var model : SQLiteModel;
		private var sqlite : SQLite;
		
		
		internal function load($model:SQLiteModel, $sqlite:SQLite) : void
		{
			model = $model;
			sqlite = $sqlite;
			sqlite.successHandler = onSuccess;
			
			var pk:String = $model[parentKey] is String ? "'"+$model[parentKey]+"'" : $model[parentKey];
			var query:String = " SELECT * FROM "+tableName + " WHERE " + foreignKey + " = "+pk;
			sqlite.runQuery(query, tableClass, Array);
		}
		
		private function onSuccess($data:Array) : void
		{
			data = $data;
			model.onLoadedRelatedData(this);
		}
		
		internal function destroy() : void
		{
			model = null;
			data = null;
			sqlite = null;
			tableClass = null;
			tableName = null;
			foreignKey = null;
			parentKey = null;
			holderColumn = null;
			columnName = null;
		}
	}
}
