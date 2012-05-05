package butterfly.air.sqlite {
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.net.Responder;
	import flash.utils.getDefinitionByName;

	/**
	 * @author solano
	 * @playerversion AIR 2.0
	 */
	public class SQLiteStatement extends SQLStatement
	{
		public var id:int;
		private var _executed:Boolean;
		public var successHandler:Function;
		public var errorHandler:Function;
		public var log : SQLiteLog;
		public var sqlResult : SQLResult;
		internal var model:SQLiteModel;
		internal var sqlite:SQLite;
		internal var collectionClass : Class;
		
		/*
		 * The object which will be saved into the table.
		 * Only available if called the method SQLite::save().
		 */ 
		internal var saveObj:Object;
		
		public function SQLiteStatement($callHandlers:Boolean=false)
		{
			super();			
			_executed = false;
			
			if($callHandlers)
			{
				addEventListener(SQLErrorEvent.ERROR, onSQLError);
		    	addEventListener(SQLEvent.RESULT, onSQLResult);   					
			}
		}

		private function onSQLResult(event : SQLEvent) : void
		{
			_executed = true;
			if(successHandler!=null)
			{
				sqlResult = getResult();
				
				if(model && (model.onModelSave == successHandler || model.onUpdatedRelatedTables == successHandler))
				{
					successHandler(this, sqlResult);					
				}
				else
				{
					var data:Array = sqlResult.data;
					var m:SQLiteModel = data && data.length>0 ? data[0] as SQLiteModel : null;
					if(m && m.getSQLite()==null)
					{
						for (var i : int = 0; i < data.length; i++) 
						{
							SQLiteModel(data[i]).setSQLite(sqlite);
						} 
					}
					if(saveObj==null) 
					{
						if(collectionClass == Array || collectionClass == null)
						{
							successHandler(sqlResult.data);							
						}
						else
						{
							var c:Class = getDefinitionByName("mx.collections.ArrayCollection") as Class;
							successHandler(new c(sqlResult.data));							
						}
					}
					else
					{
						successHandler(saveObj);						
					}
				}
			}
			dispatchEvent(new SQLiteEvent(SQLiteEvent.RESULT));
		}

		private function onSQLError(event : SQLErrorEvent) : void
		{
			sqlite.addErrorEvent(event);
			_executed = true;
			if(errorHandler!=null)
			{
				errorHandler(log);
			}
			dispatchEvent(new SQLiteEvent(SQLiteEvent.ERROR));
		}
		
		
		override public function execute(prefetch : int = -1, responder : Responder = null) : void
		{
			_executed = true;
			super.execute(prefetch, responder);
		}

		public function get executed() : Boolean
		{
			return _executed;
		}

		public function destroy() : void
		{
			removeEventListener(SQLErrorEvent.ERROR, onSQLError);
	    	removeEventListener(SQLEvent.RESULT, onSQLResult);   					
			_executed = true;
			clearParameters();
			sqlConnection = null;
			itemClass = null;
			log = null;
			successHandler = null;
			errorHandler = null;
			sqlResult = null;
			model = null;
			sqlite = null;
			saveObj = null;
		}
	}
}
