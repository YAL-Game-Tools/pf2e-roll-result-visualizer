import js.lib.RegExp;
import js.html.URLSearchParams;
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

class MedicineApp {
	static var tables:Array<RollTable> = [];
	static var inBonus:InputElement = findInput("in-bonus");
	//
	static var inEfficiency:Array<InputElement> = [
		for (i in 0 ... 4) findInput("in-efficiency-" + i)
	];
	static var inEfficiencyRanges:InputElement = findInput("in-efficiency-ranges");
	//
	static var inRollMode:SelectElement = findInput("in-roll-mode");
	static var inRollTable:InputElement = findInput("in-roll-table");
	static var inFlatChecks:InputElement = findInput("in-flat-checks");
	//
	static var inGodlessHealing:InputElement = findInput("in-godless-healing");
	static var inRobustHealth:InputElement = findInput("in-robust-health");
	static var inRobustHealthLevel:InputElement = findInput("in-robust-health-level");
	static var inMedic:InputElement = findInput("in-medic");
	static var inMagicHands:InputElement = findInput("in-magic-hands");
	static var inMortalHealing:InputElement = findInput("in-mortal-healing");
	static var inRiskySurgery:InputElement = findInput("in-risky-surgery");
	static var inForensicMedicine:InputElement = findInput("in-forensic-medicine");
	static var inForensicMedicineLevel:InputElement = findInput("in-forensic-medicine-level");
	static var inAgelessPatience:InputElement = findInput("in-ageless-patience");
	static var inAssurance:InputElement = findInput("in-assurance");
	static var inAssuranceRoll:InputElement = findInput("in-assurance-roll");
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
		~/(\d+)/g.map(inFlatChecks.value, rx -> {
			var flat = Std.parseInt(rx.matched(1));
			q.flatChecks.push(flat);
			return "";
		});
		//
		var options = [
			{ name: "Trained", dc: 15, bonus: 0 },
			{ name: "Expert", dc: 20, bonus: 10 },
			{ name: "Master", dc: 30, bonus: 30 },
			{ name: "Legendary", dc: 40, bonus: 50 },
		];
		if (inMedic.checked) {
			options[1].bonus += 5;
			options[2].bonus += 10;
			options[3].bonus += 15;
		}
		//
		var chancesPerAttempt = [];
		var efficiencyTotal = new Range(0, 0);
		for (attempt => option in options) {
			var dc = option.dc;
			var table = tables[attempt];
			if (table == null) {
				tables[attempt] = table = RollTable.create();
			} else table.element.style.display = "";
			
			//
			if (inRiskySurgery.checked || inMortalHealing.checked) q.successUpgrade = true;
			if (inAgelessPatience.checked) q.nat1Downgrade = false;
			if (inAssurance.checked) q.assurance = Std.parseInt(inAssuranceRoll.value);
			q.efficiencies = StageArray.createExt(i -> new Range(0, 0));
			q.formulas = StageArray.createExt(i -> "");
			for (i => input in inEfficiency) {
				var formula = input.value;
				if (i >= 2) { // success+
					static var rxD8 = new RegExp("d8\\b", "g");
					if (inMagicHands.checked) formula = (cast formula).replace(rxD8, "d10");
					if (option.bonus > 0) formula += " + " + option.bonus;
					if (inGodlessHealing.checked) formula += " + 5";
					if (inRobustHealth.checked) formula += " + " + inRobustHealthLevel.value;
					if (inForensicMedicine.checked) formula += " + " + inForensicMedicineLevel.value;
				}
				if (inRiskySurgery.checked) formula += " - 1d8";
				//
				var range = txr.TxrProgram.eval(formula);
				if (range == null) {
					input.classList.add("error");
					input.title = "Error: " + txr.TxrProgram.evalError;
					range = Range.fromNumber(0);
				} else {
					input.classList.remove("error");
					input.title = "Range: " + range.toStringAvg();
				}
				if (!useRanges) range = Range.fromNumber(range.avg);
				q.formulas[i + 1] = formula;
				q.efficiencies[i + 1] = range;
			}
			
			var attemptBonus = bonus;
			var result = table.update(attemptBonus, dc, q, attempt, 'DC $dc / ${option.name}');
			chancesPerAttempt.push(result.chances);
			efficiencyTotal += result.efficiency;
		}
		//
		var efficiencyDiv = document.getElementById("efficiency-div");
		if (q.efficiencies != null) {
			var snip = efficiencyTotal.toStringAvg();
			efficiencyDiv.style.display = "";
		} else efficiencyDiv.style.display = "none";
	}
	public static function main() {
		Console.log("Hello!");
		for (fieldset in document.querySelectorAll("fieldset")) {
			HtmlTools.makeFieldSetToggleable(cast fieldset);
		}
		//
		function getJSON(wantPretty:Bool) {
			var json = new DynamicAccess<Any>();
			for (field in fieldsToSaveAndLoad) {
				if (field.tagName == "INPUT" && (cast field:InputElement).type == "checkbox") {
					json[field.id] = (cast field:InputElement).checked;
				} else {
					json[field.id] = (cast field:InputElement).value;
				}
			}
			var pretty:InputElement = cast document.getElementById("in-copy-pretty");
			return wantPretty && pretty.checked ? Json.stringify(json, null, "\t") : Json.stringify(json);
		}
		function setJSON(text:String) {
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
		}
		ShareButton.createSimple("JSON",
			(then) -> then(getJSON(true)),
			(snip) -> snip,
			cast document.getElementById("in-copy")
		);
		/*document.getElementById("in-copy").addEventListener("click", (e) -> {
			var text = getJSON(true);
			function fallback() {
				Browser.window.prompt("Here's your JSON:", getJSON(false));
			}
			try {
				Browser.navigator.clipboard.writeText(text).catchError((_) -> {
					fallback();
				});
			} catch (_) {
				fallback();
			}
		});*/
		document.getElementById("in-paste").addEventListener("paste", (e:ClipboardEvent) -> {
			e.preventDefault();
			var text = e.clipboardData.getData("text/plain");
			setJSON(text);
			update();
			return false;
		});
		//
		ShareButton.create(
			() -> getJSON(false),
			(type, text) -> {
				var base = (Browser.location.hostname != "localhost"
					? 'https://yal.cc/game-tools/pf2e/medicine/'
					: Browser.location.origin + Browser.location.pathname
				);
				return '$base?params-$type=$text';
			},
			cast document.getElementById("in-share")
		);
		{ // params
			var params = new URLSearchParams(Browser.location.search);
			var p:String;
			function then(str) {
				Console.log("Loading", str);
				setJSON(str);
				update();
			}
			if ((p = params.get("params-e")) != null) {
				ShareButton.decode("e", p, then);
			} else if ((p = params.get("params-b")) != null) {
				ShareButton.decode("b", p, then);
			} else if ((p = params.get("params-c")) != null) {
				ShareButton.decode("c", p, then);
			}
		};
		//
		update();
	}
}