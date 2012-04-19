package butterfly.air.sqlite {
	import org.osmf.metadata.NullMetadataSynthesizer;
	import flash.events.SQLErrorEvent;
	import flash.data.SQLSchemaResult;
	import flash.net.Responder;
	import butterfly.air.sqlite.util.DateUtil;

	import mx.collections.ArrayCollection;

	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;


	
	
	
	
	/**
	 * @author smorales
	 * @playerversion AIR 2.0
	 */
	public dynamic class SQLite extends Proxy implements IEventDispatcher
	{
		private static var instances:Object = {};
		
		private var conn : SQLConnection;
		private var dbStatement : SQLiteStatement;
		private var file : File;
		private var proceduresDict:Object;
		private var sqlLog : SQLiteLog;
		private var isSync : Boolean;
		private var tmpSync : Boolean;
		private var intialized : Boolean;
		private var dbPath : String;
		
		[Bindable]
		public var procedures : Vector.<SQLProcedure>;
		private var statements : Vector.<SQLiteStatement>;
		private var errors : Vector.<SQLErrorEvent>;
		
		public var keepErrors:Boolean;
		
		internal var sqliteModel:SQLiteModel;
		public var successHandler:Function;
		public var errorHandler : Function;
		private var evtDispatcher : EventDispatcher;
		
		internal static function getUniqueSQLite() : SQLite
		{
			var sqlite:SQLite;
			for (var i : String in instances) 
			{
				if(sqlite != null) 
				{
					// sqlite is not null means that there are more than one istances ... 
					// so let the user define which one he wants use and return null to force an error
					return null;
				}
				sqlite = instances[i];
			}
			
			return sqlite;
		}
		
		public static function getInstance($dbPath:String, $sync:Boolean=false) : SQLite
		{
			if ( instances[$dbPath] == null )
				instances[$dbPath] = new SQLite( new SQLiteSingleton(), $dbPath, $sync );
			return instances[$dbPath];
		}
		
		public function SQLite( $key:*, $dbPath:String=null, $sync:Boolean=false )
		{
			if( !($key is SQLiteSingleton) )
		    	{throw new Error ("SQLite is a singleton class, use SQLite.getInstance($dbPath) instead");}
			
			evtDispatcher = new EventDispatcher();
			
		    isSync = true;
		    tmpSync = $sync;
			intialized = false;
		    dbPath = $dbPath;
			
			procedures = new Vector.<SQLProcedure>();
			proceduresDict = {};				
			
			open();
			markAsInitialized();
		}
		
		private function open() : void
		{
//			if(conn==null)
//			{
//				conn = new SQLConnection();
//				conn.addEventListener(SQLEvent.OPEN, onOpenedDatabase);
//				conn.addEventListener(SQLErrorEvent.ERROR, onDatabaseError);
//			}
//			else
//			{
//				conn.close();
//			}

			if(conn!=null)
			{
				conn.close();
				conn.removeEventListener(SQLEvent.OPEN, onOpenedDatabase);
				conn.removeEventListener(SQLErrorEvent.ERROR, onDatabaseError);
				return;
			}
			conn = new SQLConnection();
			conn.addEventListener(SQLEvent.OPEN, onOpenedDatabase);
			conn.addEventListener(SQLErrorEvent.ERROR, onDatabaseError);
			
			file = new File(dbPath);
			isSync ? conn.open(file) : conn.openAsync(file);
		}
		
		private function onDatabaseError($event:SQLErrorEvent) : void
		{
			addErrorEvent($event);
			if(errorHandler!=null) errorHandler($event);
		}
		
		private function onOpenedDatabase(event : SQLEvent) : void
		{
			initTable(SQLProcedure);
			checkStoredProcedures();
		}
		
		private function checkStoredProcedures() : void
		{
			if(!isSync) successHandler = onLoadedProcedures;
			var procs:ArrayCollection = load(SQLProcedure);
			if (sync)
			{
				for each (var procedure : SQLProcedure in procs) 
				{
					procedures.push(procedure);
					proceduresDict[procedure.name] = procedure;
				}
				
				dispatchEvent(new SQLiteEvent(SQLiteEvent.ON_LOADED_PROCEDURES));
			}
		}
		private function onLoadedProcedures(procs:ArrayCollection) : void
		{
			for each (var procedure : SQLProcedure in procs) 
			{
				procedures.push(procedure);
				proceduresDict[procedure.name] = procedure;
			}			
			dispatchEvent(new SQLiteEvent(SQLiteEvent.ON_LOADED_PROCEDURES));
			successHandler = null;
		}
		private function markAsInitialized() : void
		{
			if(!intialized)	
			{
				intialized = true;
				sync = tmpSync;
			}			
		}
		
		private function onClosedDB(event : SQLEvent) : void
		{
			conn.removeEventListener(SQLEvent.OPEN, onOpenedDatabase);
			conn.removeEventListener(SQLErrorEvent.ERROR, onDatabaseError);
			conn.connected;
			conn = null;
			
			open();
		}
		
		private function createStatement($query:String=null) : SQLiteStatement
		{
			if(statements==null) statements = new Vector.<SQLiteStatement>();
	    	var stmt:SQLiteStatement = new SQLiteStatement(!isSync);
		    stmt.sqlConnection = conn;
			stmt.sqlite = this;
		    if($query) stmt.text = $query;
	    	if(!isSync)
	    	{
		    	stmt.addEventListener(SQLiteEvent.ERROR, onSQLEvent);
		    	stmt.addEventListener(SQLiteEvent.RESULT, onSQLEvent);   		
			    stmt.successHandler = successHandler;
			    stmt.errorHandler = errorHandler;
			    stmt.model = sqliteModel;
	    	}
		    successHandler = null;
		    sqliteModel = null;
		    stmt.id = statements.push(stmt)-1;
		    return stmt;
		}
		private function destroyStatement($stmt:SQLiteStatement) : void
		{
	    	$stmt.removeEventListener(SQLiteEvent.RESULT, onSQLEvent);
	    	$stmt.removeEventListener(SQLiteEvent.ERROR, onSQLEvent);
			$stmt.destroy();
			if($stmt.id < statements.length) statements[$stmt.id] = null;
		}
		
		private function onSQLEvent(event : SQLiteEvent) : void
		{
			var stmt:SQLiteStatement = event.target as SQLiteStatement;
			destroyStatement(stmt);
			stmt = getNextStatement();
			if(stmt) stmt.execute();
		}
		
		private function getNextStatement() : SQLiteStatement
		{
			for (var i : Number = 0; i < statements.length; i++) 
			{
				var stmt:SQLiteStatement = statements[i];
				if(stmt==null) continue;
				if(stmt.executing) return null;
				if(!stmt.executed && stmt.sqlConnection!=null) return stmt;
			}
			
			return null;
		}
		
		private function prepareStatement($stmt:SQLiteStatement, $methodName:*, $args:Array) : void
		{
			var procedure : SQLProcedure = proceduresDict[$methodName];
			if(procedure==null) throw new SQLError("Procedure", "Stored procedure '"+ $methodName +"' not found");
			
		    $stmt.text = procedure.query;
		    sqlLog.procName = $methodName;
		    sqlLog.query = procedure.query;
		    
		    if($args.length>0 && !($args[0] is Class)) 
		    {
		    	parseVariables($stmt, $args[0]);
		    }
		    else if($args.length>0 && $args[0] is Class) 
		    {
		    	$stmt.itemClass = $args[0] as Class;
		    	sqlLog.castingClass = $args[0] as Class;
		    	
			    if($args.length>1 && !($args[1] is Class)) 
			    {
			    	parseVariables($stmt, $args[1]);
			    }
		    }
		    
		    if($args.length > 1 && $args[1] is Class) 
		    {
		    	$stmt.itemClass = $args[1] as Class;			
		    	sqlLog.castingClass = $args[1] as Class;
		    }
		}
		
		private function parseVariables($stmt:SQLiteStatement, $vars:Object) : void
		{
			for (var i : String in $vars) 
			{
				$stmt.parameters[ '@'+i ] = $vars[i];
				sqlLog.addParamter('@'+i, $vars[i]);
			}
		}
		
		
		private function getDBType($type:String) : String
		{
			switch($type)
			{
				case 'int':
					return "INTEGER";
					break;
				case 'Date':
					return "DATETIME";
					break;
				case 'Number':
					return "REAL";
					break;
				case 'String':
					return "TEXT";
					break;
				case 'Boolean':
					return "BOOL";
					break;
				case 'flash.utils::ByteArray':
					return "BLOB";
					break;
				case 'mx.collections::ArrayCollection':
					return "OBJECT";
					break;
				default:
					return "TEXT";
			}
		}
				
		internal function addErrorEvent($error:SQLErrorEvent) : void
		{
			if(keepErrors)
			{
				if(errors == null ) errors = new Vector.<SQLErrorEvent>();
				errors.push($error);
			}
		}
		
		/**
		 * Only if connection sync==true.
		 */
		public function close() : void
		{
			if(conn!=null && isSync)
			{
				conn.removeEventListener(SQLEvent.OPEN, onOpenedDatabase);
				conn.removeEventListener(SQLErrorEvent.ERROR, onDatabaseError);
				conn.close();
				conn = null;				
			}
		}
		
		public function getErrors() : Vector.<SQLErrorEvent>
		{
			return errors;
		}
		
		/**
		 * Traces the last log to the console.
		 */
		public function printLog() : void
		{
			sqlLog.printLog();
		}
		
		/**
		 * Returns the last log to the console.
		 */
		public function get log() : SQLiteLog
		{
			return sqlLog;
		}
		
		/**
		 * @return The database file path.
		 */
		public function get path() : String
		{
			return dbPath;
		}
		
		/**
		 * Indicates whether this connection is currently involved in a transaction.
		 */
		public function get inTransaction () : Boolean
		{
			return conn.inTransaction;
		}
		
		public function loadSchema() : void
		{
			conn.loadSchema();
		}
		
		public function getSchemaResult() : SQLSchemaResult
		{
			return conn.getSchemaResult();
		}
		
		/**
		 * Begins a transaction within which all SQL statements executed against the connection's database or databases are grouped.
		 * 
		 * @see flash.data.SQLConnection#begin() 
		 */
		public function begin($option:String=null, $responder:Responder=null) : void
		{
			conn.begin($option, $responder);
		}
	
		/**
		 * Commits an existing transaction, causing any actions performed by the transaction's statements to be permanently applied to the database.
		 * 
		 * @see flash.data.SQLConnection#commit() 
		 */
		public function commit($responder:Responder=null) : void
		{
			conn.commit($responder);
		}
		
		/**
		 * @param $obj		A Class or instance. If the table for the class or instance class exists all 
		 * 					rows are selected and returned.
		 */
		public function load($obj : *, $whereClause:String="") : ArrayCollection
		{
			var table:SQLiteTable = SQLiteTable.getTable($obj);
			var query:String = table.querySelect + " " + ($whereClause!="" ? "WHERE "+$whereClause : "");
//			var query:String = "select * from "+table.tableName + " " + ($whereClause!="" ? "WHERE "+$whereClause : "");
			return runQuery(query, table.tableClass);
		}
		
		/**
		 * Creates a procedure.
		 * 
		 * @example
		 * <listing version='3.0'>
		 * var db:SQLite = SQLite.getInstance(myDatabaseFilePath);
		 * 
		 * db.storeProcedure("getUserByName", "select * from User where firstName like '%&#64;name%'");
		 * .
		 * .
		 * .
		 * // then you can use the procedure elsewhere in your code
		 * var result:ArrayCollection = db.getUserByName(User, {name:'john'});
		 * if(result.length>0) trace(result[0]);
		 * 
		 * </listing>
		 * 
		 * @param $procName		The name of the procedure.
		 * @param $procedure	The query.
		 */
		public function storeProcedure($procName:String, $procedure:String) : void
		{
			var procedure:SQLProcedure = new SQLProcedure();
						
			for each (var proc : SQLProcedure in procedures) 
			{
				if(proc.name == $procName) 
				{
					procedure = proc;
				}
			}
						
			if(procedure.name == null) 
			{
				procedures.push(procedure);
				proceduresDict[procedure.name] = procedure;
			}
			
			procedure.name = $procName;
			procedure.query = $procedure;
			
			save(procedure);
			
			checkStoredProcedures();
		}
		
		/**
		 * Saves an instance to its belonging table.
		 * 
		 * @param $instance		The object you want save.
		 */
		public function save($instance : Object) : *
		{
			var table:SQLiteTable = SQLiteTable.getTable($instance);

			if (!($instance is SQLProcedure) && proceduresDict["$intern$save" + table.tableName] != null)
			{
				var args:Object = {};
				
				if ($instance is SQLiteModel)
				{
					sqliteModel = SQLiteModel($instance);
					args = sqliteModel.getInsertValues();
				}
				else
				{
					for each (var n : XML in table.xmlDescription..accessor) 
					{
						if (n.@access == "readwrite")
						{
							var colValue:* = $instance[n.@name];
							if (n.@name == "id" && (colValue <= 0) ) 
							{
								args[n.@name] = null;
							}
							else
							{
								args[n.@name] = $instance[n.@name];							
							}
						}
					}					
				}
				
				flash_proxy::callProperty("$intern$save"+table.tableName, args);
			}
			else
			{
				var values:String = " values (";
				var query:String = "REPLACE INTO "+table.tableName.toLowerCase()+" (";
				var col:String = "";
				
				if( $instance.hasOwnProperty('id') && $instance['id'] != -1)
				{
					query += " id, ";
					values += $instance["id"] + ", ";
				}
				
				for each (var node : XML in table.xmlDescription..accessor) 
				{
					if(node.@access == "readwrite" && node.@name != "id")
					{
						var dbType:String = getDBType(node.@type).toLowerCase();
						var isText:Boolean = dbType.indexOf("text")!=-1 || dbType.indexOf("varchar")!=-1 || dbType.indexOf("char")!=-1;
						var quote:String = isText ? "'" : "";
						var value:String = isText ? String($instance[node.@name]).replace(/'/g, "''") : $instance[node.@name];
						
						//check if value is a date object
						if(dbType == 'datetime' && $instance[node.@name]!=null) value = "'"+DateUtil.convertToSQLDate($instance[node.@name])+"'";
						
						query += col + node.@name + " ";
						values += col  + quote + value + quote + " ";
						col = ", ";
					}
				}
				query += ")" + values + ")";
				return runQuery(query);				
			}
		}
		
		
		/**
		 * Initializes a model class and creates the corresponding table if it doesn't exist.
		 * Make sure that the given class is bindable. Case the model has child tables/models,
		 * the class should extend <code>SQLiteModel</code>. 
		 * 
		 * @example
		 * <listing version='3.0'>
		 * //your sample class
		 * [Bindable] 
		 * public class User
		 * {
		 * 	[PrimaryKey]
		 * 	public var id:int;
		 * 	public var firstName:String;
		 * 	public var lastName:String;
		 * 	
		 * 	[RelatedTable(table="Phone", foreignKey="idContact")]
		 * 	public var phone:ArrayCollection; //could be also type of Vector.&lt;Phone&gt; or Array 
		 * 	public var address:String;
		 * }
		 * 
		 * [Bindable]
		 * [ForeignKey(parentTable="Contact", childKeys="idContact", parentKeys="id")]
		 * public class Phone
		 * {
		 * 	[PrimaryKey]
		 * 	public var id:int;
		 * 	public var idContact:int;
		 * 	
		 * 	//The phone type like "Home", "Mobile", "Work" etc.
		 * 	public var phoneType:String; 
		 * 	public var number:String; 
		 * }
		 * 
		 * var db:SQLite = SQLite.getInstance("your/Database/file/path/addresses.db");
		 * db.createTable(User);
		 * </listing>
		 * 
		 * @see butterfly.air.sqlite.SQLiteModel
		 * 
		 * @param $tableClass		The model class which represents a table.
		 */
		public function initTable($model : Class) : Boolean
		{
			var table:SQLiteTable = SQLiteTable.initTable($model, this);
			
			var result:Boolean = true;
			try
			{
				sqlLog = new SQLiteLog();
				sqlLog.query = table.queryCreateTable;
				
				var stmt:SQLiteStatement = createStatement(table.queryCreateTable);
			    if(isSync) 
			    {
			    	stmt.execute();
			    }
			    storeProcedure("$intern$save"+table.tableName, table.queryReplaceInto);
			}
			catch ($e: SQLError)
			{
				sqlLog.sqlError = $e;
				sqlLog.printLog();
				result = false;
			}
			
			return result;
		}
		
		
		/**
		 * Runs a query and returns optionally the result casted to a type.
		 * 
		 * @example
		 * <listing version='3.0'>
		 * var db:SQLite = SQLite.getInstance(yourDatabaseFilePath);
		 * var result:ArrayCollection = db.runQuery("select * from User", User);
		 * if(result.length>0) var firstUser:User = result[0];
		 * </listing>
		 * 
		 * @param $query		The query to be run.
		 * @param $castClass	The class to cast each returned row.
		 */
		public function runQuery($query:String, $castClass:Class=null) : ArrayCollection
		{
			var result : ArrayCollection = new ArrayCollection();
			if($query == "" || $query == null) return result;
			
			try
			{
				sqlLog = new SQLiteLog();
				sqlLog.query = $query;
				sqlLog.castingClass = $castClass;
				var stmt:SQLiteStatement = createStatement($query);
				if($castClass!=null) stmt.itemClass = $castClass;
				
				if(isSync)
				{
				    stmt.execute();
					var dbResult:SQLResult = stmt.getResult();
					result = new ArrayCollection(dbResult.data);
				}
				else
				{
					var stmt2:SQLiteStatement = getNextStatement();
					if(stmt2) 
					{
						stmt2.execute();
					}
				}
			}
			catch ($e: SQLError)
			{
				sqlLog.sqlError = $e;
				sqlLog.printLog();
			}
			
			return result;
		}
		
		/**
		 * 
		 */
		public function get sync() : Boolean
		{
			return isSync;
		}
		public function set sync($value:Boolean) : void
		{			
			if(conn.connected && isSync!=$value)
			{
				conn.addEventListener(SQLEvent.CLOSE, onClosedDB);
				conn.close();
			}
			isSync = $value;
		}
		
		
		override flash_proxy function callProperty($methodName:*, ... $args):*
		{
			try
			{
				sqlLog = new SQLiteLog();
				var stmt:SQLiteStatement = createStatement();
			    prepareStatement(stmt, $methodName, $args);
				
				if(isSync)
				{
				    stmt.execute();
					var result:SQLResult = stmt.getResult();
					return new ArrayCollection(result.data);
				}
				else
				{
					var stmt2:SQLiteStatement = getNextStatement();
					if(stmt2) stmt2.execute();
				}
			}
			catch ($e: SQLError)
			{
				sqlLog.sqlError = $e;
				sqlLog.printLog();
			}
		}
		
		
		override flash_proxy function getProperty($name:*):*
		{
			if(this[$name] != null)
			{
				return this[$name];
			}
			else
			{
				return null;
			}
		}
		
		override flash_proxy function setProperty(name:*, value:*):void 
		{
		}
		
		
		
		
		public function dispatchEvent(event : Event) : Boolean
		{
			return evtDispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type : String) : Boolean
		{
			return evtDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type : String) : Boolean
		{
			return evtDispatcher.willTrigger(type);
		}
		
		public function removeEventListener(type : String, listener : Function, useCapture : Boolean = false) : void
		{
			evtDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function addEventListener(type : String, listener : Function, useCapture : Boolean = false, priority : int = 0, useWeakReference : Boolean = false) : void
		{
			evtDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function toString() : String
		{
			return "butterfly.air.sqlite.SQLite ["+path+"]";
		}
	}
}


class SQLiteSingleton
{
}
















































