package;

import RollTable.StageArray;
import js.html.Element;
import js.html.SelectElement;
import js.html.Console;
import js.Browser;
import js.Browser.document;
import js.html.InputElement;
using HtmlTools;

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
	//
	static var inRollMode:SelectElement = findInput("in-roll-mode");
	static var inRollTable:InputElement = findInput("in-roll-table");
	static var inKeenFlair:InputElement = findInput("in-keen-flair");
	static var inFlatChecks:InputElement = findInput("in-flat-checks");
	static var inStoredEfficiency:InputElement = findInput("in-efficiency-ref");
	static var outEfficiencyResult = document.getElementById("efficiency-result");
	static var outEfficiency = 0.;
	//
	static function findInput<T:Element>(id:String, ?c:Class<T>):T {
		var input:T = cast document.getElementById(id);
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
			default: RollOnce;
		}
		inRollTable.disabled = q.rollMode == RollOnce;
		q.rollTable = q.rollMode != RollOnce && inRollTable.checked;
		if (inUseEfficiency.checked) {
			q.efficiencies = new StageArray(0.);
			for (i => input in inEfficiency) {
				q.efficiencies[i + 1] = input.valueAsNumber;
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
		var efficiencyTotal = 0.;
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
			var efficiency = table.update(attemptBonus, dc, q);
			if (attempt == 0) q.firstEfficiency = efficiency;
			efficiencyTotal += efficiency;
		}
		//
		for (extra in attempts ... tables.length) {
			tables[extra].element.style.display = "none";
		}
		//
		var efficiencyDiv = document.getElementById("efficiency-div");
		if (q.efficiencies != null) {
			outEfficiency = efficiencyTotal;
			var snip = efficiencyTotal.toFixed2();
			if (inStoredEfficiency.value != "") {
				var efficiencyRef = inStoredEfficiency.valueAsNumber;
				if (Math.isFinite(efficiencyRef)) {
					snip += " (" + (efficiencyTotal / efficiencyRef * 100).toFixed2() + "%)";
				}
			}
			outEfficiencyResult.innerText = snip;
			efficiencyDiv.style.display = "";
		} else efficiencyDiv.style.display = "none";
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
			inStoredEfficiency.valueAsNumber = outEfficiency;
			update();
		});
		document.getElementById("in-efficiency-clear").addEventListener("click", (e) -> {
			inStoredEfficiency.value = "";
			update();
		});
		//
		update();
	}
}