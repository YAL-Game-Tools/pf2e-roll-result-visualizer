package tools;
import js.html.Node;
import haxe.extern.EitherType;
import haxe.extern.Rest;
import js.html.FieldSetElement;
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
	public static inline function toPercent(n:Float) {
		return toFixed2(n) + "%";
	}
	public static function makeFieldSetToggleable(q:FieldSetElement) {
		q.classList.add("toggleable");
		var legend = q.querySelector("& > legend");
		legend.onclick = (e) -> {
			if (q.classList.contains("hide")) {
				q.classList.remove("hide");
			} else {
				q.classList.add("hide");
			}
		}
	}
	public static function appendMixed(el:Element, values:Rest<EitherType<String, Node>>) {
		for (item in values) {
			el.append(item);
		}
	}
}