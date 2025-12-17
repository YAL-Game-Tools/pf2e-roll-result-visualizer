package;

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
	static var inUseEfficiency:InputElement = findInput("in-use-efficiency");
	static var inEfficiency:Array<InputElement> = [
		for (i in 0 ... 4) findInput("in-efficiency-" + i)
	];
	static var inSureStrike:InputElement = findInput("in-sure-strike");
	static function findInput(id:String) {
		var input:InputElement = cast document.getElementById(id);
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
		var map = Std.parseInt(inMAP.value);
		var efficiencies = if (inUseEfficiency.checked) {
			[for (input in inEfficiency) input.valueAsNumber];
		} else null;
		//
		var sureStrike = inSureStrike.checked;
		var firstEfficiency = 0.;
		var efficiencyTotal = 0.;
		for (attempt in 0 ... attempts) {
			var table = tables[attempt];
			if (table == null) {
				tables[attempt] = table = RollTable.create();
			} else table.element.style.display = "";
			
			var efficiency = table.update(bonus, dc, efficiencies, firstEfficiency, sureStrike);
			if (attempt == 0) firstEfficiency = efficiency;
			efficiencyTotal += efficiency;
			bonus -= map;
		}
		//
		for (extra in attempts ... tables.length) {
			tables[extra].element.style.display = "none";
		}
		//
		var efficiencyResult = document.getElementById("efficiency-result");
		if (efficiencies != null) {
			efficiencyResult.innerText = "Efficiency total: " + efficiencyTotal.toFixed2();
		} else efficiencyResult.innerText = "";
	}
	public static function main() {
		Console.log("Hello!");
		var efficiencyPresets:SelectElement = cast document.getElementById("in-efficiency-presets");
		efficiencyPresets.addEventListener("change", () -> {
			var value = efficiencyPresets.value;
			if (value == "") return;
			var parts = value.split("/");
			for (i => part in parts) inEfficiency[i].value = part;
			//efficiencyPresets.value = "";
			update();
		});
		update();
	}
}