import js.html.Element;
import js.Browser;

class HtmlTools {
	public static function find<T:Element>(id:String, ?c:Class<T>):T {
		return cast Browser.document.getElementById(id);
	}
	public static inline function toFixed1(n:Float):String {
		return "" + Math.round(n * 10) / 10;
	}
	public static inline function toFixed2(n:Float):String {
		return "" + Math.round(n * 100) / 100;
	}
}