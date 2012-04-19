package butterfly.air.sqlite.util
{
	/**
	 * @author Solano Morales  |  F5 Web Design e Tecnologia Atualizada
	 * @playerversion AIR 2.0
	 * @private
	 */
	public class DateUtil
	{
		public function DateUtil()
		{
			throw new Error("DateUtil can't be instantiated! Use the static methods.");
		}

		/**
		 * @param $lang			The language
		 * 						Possible values are:<br />
		 * 						'pt', 'eng', 'de', 'es'
		 * 
		 * @param $letters		The count letters of the name.
		 * 						E.g. if $letters = 2, then monday will come as 'Mo'.
		 * 
		 * @param $case			Defines if the names are in normal case, upper case or lower case.<br />
		 * 						  -1 = lower case<br />
		 * 						  0 = normal case<br />
		 * 						  1 = upper case
		 */
		public static function getWeekDayNames($lang : String, $letters : int = 0, $case : int = 0) : Array
		{
			var days : Array;

			switch($lang)
			{
				case 'pt':
					days = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
					break;
				case 'de':
					days = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
					break;
				case 'es':
					days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
					break;
				default:
					days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
			}

			var i : Number;

			if ($letters > 0)
			{
				for ( i = 0; i < days.length; i++)
				{
					days[i] = String(days[i]).substr(0, $letters);
				}
			}

			if ($case != 0)
			{
				for ( i = 0; i < days.length; i++)
				{
					days[i] = $case>0 ? String(days[i]).toUpperCase() : String(days[i]).toLowerCase();
				}
			}

			return days;
		}

		/**
		 * @param $lang			The language
		 * 						Possible values are:<br />
		 * 						'pt', 'eng', 'de', 'es'
		 * 
		 * @param $letters		The count letters of the name.
		 * 						E.g. if $letters = 2, then monday will come as 'Mo'.
		 * 						
		 * @param $case			Defines if the names are in normal case, upper case or lower case.<br />
		 * 						  -1 = lower case<br />
		 * 						  0 = normal case<br />
		 * 						  1 = upper case
		 */
		public static function getMonthNames($lang : String, $letters : int = 0, $case : int = 0) : Array
		{
			var month : Array;

			switch($lang)
			{
				case 'pt':
					month = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
					break;
				case 'de':
					month = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
					break;
				case 'es':
					month = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
					break;
				default:
					month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
			}

			var i : Number;

			if ($letters > 0)
			{
				for ( i = 0; i < month.length; i++)
				{
					month[i] = String(month[i]).substr(0, $letters);
				}
			}

			if ($case != 0)
			{
				for ( i = 0; i < month.length; i++)
				{
					month[i] = $case == -1 ? String(month[i]).toLowerCase() : String(month[i]).toUpperCase();
				}
			}

			return month;
		}

		public static function compareDates($date1 : Date, $date2 : Date) : int
		{
			var d1 : Date = new Date(Date.parse($date1));
			var d2 : Date = new Date(Date.parse($date2));

			d1.setHours(0);
			d1.setMinutes(0);
			d1.setSeconds(0);
			d2.setHours(0);
			d2.setMinutes(0);
			d2.setSeconds(0);

			return d1 > d2 ? 1 : d1 < d2 ? -1 : 0;
		}

		public static function compareDateTimes($date1 : Date, $date2 : Date) : int
		{
			return $date1.getTime() > $date2.getTime() ? 1 : $date1.getTime() < $date2.getTime() ? -1 : 0;
		}

		public static function convertToSQLDate($date : Date) : String
		{
			if($date==null) return null;
			
			var Y : String = $date.fullYear + "";
			var M : String = $date.month+1 < 10 ? "0" + ($date.month + 1) : "" + ($date.month + 1);
			var D : String = $date.date < 10 ? "0" + $date.date : "" + $date.date;

			var h : String = $date.hours < 10 ? "0" + $date.hours : "" + $date.hours;
			var m : String = $date.minutes < 10 ? "0" + $date.minutes : "" + $date.minutes;
			var s : String = $date.seconds < 10 ? "0" + $date.seconds : "" + $date.seconds;

			return Y + "-" + M + "-" + D + " " + h + ":" + m + ":" + s;
		}

		public static function getWeekNumber(date : Date) : int
		{
			var days : Array = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
			var year : Number = date.fullYearUTC;
			var isLeap : Boolean = (year % 4 == 0) && (year % 100 != 0) || (year % 100 == 0) && (year % 400 == 0);
			if (isLeap)
				days[1]++;
			
			var d:Number = 0;
			// month is conveniently 0 indexed.
			for (var i:Number = 0; i < date.monthUTC; i++)
				d += days[i];
			d += date.dateUTC;
			
			var temp : Date = new Date(year, 0, 1);
			var jan1 : Number = temp.dayUTC;
			/**
			 * If Jan 1st is a Friday (as in 2010), does Mon, 4th Jan 
			 * fall in the first week or the second one? 
			 *
			 * Comment the next line to make it in first week
			 * This will effectively make the week start on Friday 
			 * or whatever day Jan 1st of that year is.
			 **/
			d += jan1;
			
			return (d / 7);
		}
	}
}




































































