package;

import txr.Range;
import js.html.ClipboardEvent;
import haxe.Json;
import haxe.DynamicAccess;
import RollTable.StageArray;
import js.html.Element;
import js.html.SelectElement;
import js.html.Console;
import js.Browser;
import js.Browser.document;
import js.html.InputElement;
using HtmlTools;
// https://evanhahn.com/javascript-compression-streams-api-with-strings
// https://github.com/basro/hx-jsasync

class Main {
	static var tables:Array<RollTable> = [];
	static var inBonus:InputElement = findInput("in-bonus");
	static var inDC:InputElement = findInput("in-dc");
	static var inAttempts:InputElement = findInput("in-attempts");
	static var inMAP:InputElement = findInput("in-map");
	//
	static var inUseEfficiency:InputElement = findInput("in-use-efficiency");
	static var inEfficiency:Array<InputElement> = [
		for (i in 0 ... 4) findInput("in-efficiency-" + i)
	];
	static var inEfficiencyRanges:InputElement = findInput("in-efficiency-ranges");
	static var inForcefulEfficiency:InputElement = findInput("in-forceful-efficiency");
	//
	static var inRollMode:SelectElement = findInput("in-roll-mode");
	static var inRollTable:InputElement = findInput("in-roll-table");
	static var inKeenFlair:InputElement = findInput("in-keen-flair");
	static var inFlatChecks:InputElement = findInput("in-flat-checks");
	static var inStoredEfficiency:InputElement = findInput("in-efficiency-ref");
	//
	static var inMultiHit:InputElement = findInput("in-use-multi");
	static var inMultiHitTable:InputElement = findInput("in-multi-table");
	//
	static var outEfficiencyResult = document.getElementById("efficiency-result");
	static var outEfficiency = new Range(0, 0);
	//
	public static var fieldsToSaveAndLoad:Array<Element>;
	static function findInput<T:Element>(id:String, ?c:Class<T>):T {
		var input:T = cast document.getElementById(id);
		if (fieldsToSaveAndLoad == null) {
			fieldsToSaveAndLoad = [
				document.getElementById("in-notes"),
			];
		}
		fieldsToSaveAndLoad.push(input);
		input.addEventListener("change", () -> {
			update();
		});
		return input;
	}
	public static function update() {
		var bonus = Std.parseInt(inBonus.value);
		var dc = Std.parseInt(inDC.value);
		var attempts = Std.parseInt(inAttempts.value);
		if (attempts < 1) attempts = 1;
		//
		var q = new RollConfig();
		q.rollMode = switch (inRollMode.value) {
			case "2kh": KeepHigher;
			case "2kl": KeepLower;
			case "followup": FollowUpStrike;
			default: RollOnce;
		}
		var isRoll2 = q.rollMode.isPair();
		inRollTable.disabled = !isRoll2;
		q.rollTable = isRoll2 && inRollTable.checked;
		//
		var useRanges = inEfficiencyRanges.checked;
		if (inUseEfficiency.checked) {
			q.efficiencies = StageArray.createExt(i -> new Range(0, 0));
			for (i => input in inEfficiency) {
				var range = txr.TxrProgram.eval(input.value);
				if (range == null) {
					input.classList.add("error");
					range = Range.fromNumber(0);
				} else input.classList.remove("error");
				if (!useRanges) range = Range.fromNumber(range.avg);
				q.efficiencies[i + 1] = range;
			}
			//
			var forcefulEfficiency = inForcefulEfficiency.valueAsNumber;
			if (Math.isFinite(forcefulEfficiency)) {
				q.forcefulEfficiency = forcefulEfficiency;
			}
		}
		q.keenFlair = inKeenFlair.checked;
		~/(\d+)/g.map(inFlatChecks.value, rx -> {
			var flat = Std.parseInt(rx.matched(1));
			q.flatChecks.push(flat);
			return "";
		});
		//
		var mapPerAttempt = [0];
		~/(-?\d+)/g.map(inMAP.value, rx -> {
			var flat = Std.parseInt(rx.matched(1));
			mapPerAttempt.push(flat);
			return "";
		});
		if (mapPerAttempt.length == 1) mapPerAttempt.push(-5);
		if (mapPerAttempt.length < 3) mapPerAttempt.push(mapPerAttempt[1] * 2);
		//
		var chancesPerAttempt = [];
		var efficiencyTotal = new Range(0, 0);
		for (attempt in 0 ... attempts) {
			var table = tables[attempt];
			if (table == null) {
				tables[attempt] = table = RollTable.create();
			} else table.element.style.display = "";
			
			var attemptBonus = bonus;
			if (attempt < mapPerAttempt.length) {
				attemptBonus += mapPerAttempt[attempt];
			} else {
				attemptBonus += mapPerAttempt[mapPerAttempt.length - 1];
			}
			var result = table.update(attemptBonus, dc, q, attempt);
			if (attempt == 0) q.firstEfficiency = result.efficiency;
			chancesPerAttempt.push(result.chances);
			efficiencyTotal += result.efficiency;
		}
		//
		for (extra in attempts ... tables.length) {
			tables[extra].element.style.display = "none";
		}
		//
		var efficiencyDiv = document.getElementById("efficiency-div");
		if (q.efficiencies != null) {
			outEfficiency = efficiencyTotal;
			var snip = efficiencyTotal.toStringAvg();
			if (inStoredEfficiency.value != "") {
				var efficiencyRef = txr.TxrProgram.eval(inStoredEfficiency.value);
				if (efficiencyRef != null) {
					var rangeRatio = (efficiencyTotal / efficiencyRef * 100);
					if (!rangeRatio.isPoint()) {
						var avgRatio = (efficiencyTotal.avg / efficiencyRef.avg * 100).toFixed2();
						snip += ' (${rangeRatio.toString()}%, $avgRatio% avg)';
					} else {
						snip += ' (${rangeRatio.toString()}%)';
					}
				}
			}
			outEfficiencyResult.innerText = snip;
			efficiencyDiv.style.display = "";
		} else efficiencyDiv.style.display = "none";
		//
		if (inMultiHit.checked) {
			MultiHit.useTable = inMultiHitTable.checked;
			MultiHit.calc(chancesPerAttempt);
		} else MultiHit.clear();
		//
	}
	public static function main() {
		Console.log("Hello!");
		for (fieldset in document.querySelectorAll("fieldset")) {
			HtmlTools.makeFieldSetToggleable(cast fieldset);
		}
		//
		var efficiencyPresets:SelectElement = cast document.getElementById("in-efficiency-presets");
		efficiencyPresets.addEventListener("change", () -> {
			var value = efficiencyPresets.value;
			if (value == "") return;
			var parts = value.split("/");
			for (i => part in parts) inEfficiency[i].value = part;
			//efficiencyPresets.value = "";
			update();
		});
		//
		document.getElementById("in-efficiency-store").addEventListener("click", (e) -> {
			inStoredEfficiency.value = outEfficiency.toStringFull();
			update();
		});
		document.getElementById("in-efficiency-clear").addEventListener("click", (e) -> {
			inStoredEfficiency.value = "";
			update();
		});
		//
		document.getElementById("in-multi-store").addEventListener("click", (e) -> {
			MultiHit.stored = MultiHit.latest;
			update();
		});
		document.getElementById("in-multi-clear").addEventListener("click", (e) -> {
			MultiHit.stored = null;
			update();
		});
		//
		fieldsToSaveAndLoad.remove(inStoredEfficiency);
		document.getElementById("in-copy").addEventListener("click", (e) -> {
			var json = new DynamicAccess<Any>();
			for (field in fieldsToSaveAndLoad) {
				if (field.tagName == "INPUT" && (cast field:InputElement).type == "checkbox") {
					json[field.id] = (cast field:InputElement).checked;
				} else {
					json[field.id] = (cast field:InputElement).value;
				}
			}
			var pretty:InputElement = cast document.getElementById("in-copy-pretty");
			var text = pretty.checked ? Json.stringify(json, null, "\t") : Json.stringify(json);
			Browser.navigator.clipboard.writeText(text);
		});
		document.getElementById("in-paste").addEventListener("paste", (e:ClipboardEvent) -> {
			e.preventDefault();
			var text = e.clipboardData.getData("text/plain");
			var json:DynamicAccess<Any> = Json.parse(text);
			for (field in fieldsToSaveAndLoad) {
				var value = json[field.id];
				if (value == null) continue;
				if (value is Bool) {
					if (field.tagName == "INPUT" && (cast field:InputElement).type == "checkbox") {
						(cast field:InputElement).checked = value;
					}
					continue;
				}
				(cast field:InputElement).value = value;
			}
			update();
			return false;
		});
		//
		update();
	}
}