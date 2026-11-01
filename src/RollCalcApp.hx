import damage.DamageFormula;
import js.html.ClipboardEvent;
import haxe.Json;
import js.html.URLSearchParams;
import js.html.InputElement;

class RollCalcApp {
	public static var container = document.getElementById("results");
	public static var notesField:InputElement = find("notes");
	public static function get() {
		var arr = [];
		for (el in container.querySelectorAll("& > .damage-formula")) {
			var f = DamageFormula.ofElement(cast el);
			if (f != null) arr.push(f);
		}
		return arr;
	}
	public static function updateRatios() {
		var all = get();
		var max = 0.;
		for (f in all) {
			var r = f.range;
			if (r != null) max = Math.max(max, r.avg);
		}
		for (f in all) {
			var r = f.range;
			if (r != null) {
				if (max > 0) {
					f.ratio.innerText = (cast (r.avg / max * 100)).toFixed(1) + "%";
				} else f.ratio.innerText = "100.0%";
			}
		}
	}
	public static function main() {
		function addEmpty() {
			var next = new DamageFormula();
			container.append(next.fieldSet);
			next.update();
		}
		if ((cast window).hxGetSearchParams != null) {
			var pairs:Array<{ key:String, value:String }> = (cast window).hxGetSearchParams();
			var note = pairs.find(p -> p.key == "t")?.value;
			if (note != null) notesField.value = note;
			var label = "";
			var found = 0;
			for (pair in pairs) {
				if (pair.key == "n") {
					label = pair.value;
				} else if (pair.key == "d") {
					var f = new DamageFormula();
					f.label = label;
					f.formula = pair.value;
					f.autoSize();
					container.append(f.fieldSet);
					f.update();
					found += 1;
				}
			}
			if (found == 0) addEmpty();
		} else addEmpty();
		//
		document.getElementById("add-line").onclick = e -> {
			addEmpty();
		};
		//
		ShareButton.createSimple(
			"share URL",
			(then) -> {
				var params = new URLSearchParams();
				var notes = notesField.value.trim();
				if (notes != "") params.append("t", notes);
				for (f in get()) {
					params.append("n", f.legendText.innerText);
					params.append("d", f.field.value);
				}
				var base = (document.location.hostname != "localhost"
					? 'https://yal.cc/game-tools/pf2e/roll-calc/'
					: document.location.origin + document.location.pathname
				);
				var paramStr = "" + params;
				paramStr = paramStr.replace("(", "%28");
				paramStr = paramStr.replace(")", "%29");
				then('$base?$paramStr');
			},
			(url) -> url,
			find("share")
		);
		//
		var pretty:InputElement = find("copy-pretty");
		ShareButton.createSimple(
			"JSON",
			(then) -> {
				var json:RollCalcData = {
					caption: notesField.value,
					items: get().map(f -> ({ label: f.label, formula: f.formula }))
				};
				if (pretty.checked) {
					then(Json.stringify(json, null, "\t"));
				} else then(Json.stringify(json));
			},
			(url) -> url,
			find("copy")
		);
		var pasteHere:InputElement = find("paste");
		pasteHere.addEventListener("paste", (e:ClipboardEvent) -> {
			e.preventDefault();
			var text = e.clipboardData.getData("text/plain");
			var json:RollCalcData = Json.parse(text);
			//
			for (f in get()) f.fieldSet.remove();
			//
			notesField.value = json.caption;
			for (pair in json.items) {
				var f = new DamageFormula();
				f.label = pair.label;
				f.formula = pair.formula;
				f.autoSize();
				container.append(f.fieldSet);
			}
			//
			return false;
		});
	}
}
typedef RollCalcData = {
	caption:String,
	items:Array<{
		label:String,
		formula:String,
	}>
}
