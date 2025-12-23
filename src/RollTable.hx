import haxe.ds.Vector;
import js.html.TableRowElement;
import js.html.DivElement;
import js.Browser;
import js.html.TableElement;
import js.html.LegendElement;
import js.html.FieldSetElement;
import js.Browser.document;
import js.html.TableCellElement;
import js.html.Element;
using HtmlTools;

class RollTable {
	public var element:FieldSetElement;
	public var legend:LegendElement;
	public var table:TableElement;
	public var dice:Array<TableCellElement> = [null];
	public var dieRow:TableRowElement;
	public var sureStrikeDice:Array<Array<TableCellElement>> = [];
	public var sureStrikeRows:Array<TableRowElement> = [];
	public var stages:Array<TableCellElement> = [];
	public var footnotes:DivElement;
	public static var stageClassNames = {
		var names = new StageArray("");
		names[FlatFailure] = "flat-failure";
		names[CritFailure] = "crit-failure";
		names[Failure] = "failure";
		names[Success] = "success";
		names[CritSuccess] = "crit-success";
		names;
	};
	public function new() {
		element = document.createFieldSetElement();
		legend = document.createLegendElement();
		table = document.createTableElement();
		table.classList.add("results");
		
		dieRow = document.createTableRowElement();
		dieRow.classList.add("dice", "normal");
		for (i in 1 ... 21) {
			var die = document.createTableCellElement();
			die.width = "5%";
			die.append("" + i);
			dieRow.append(die);
			dice.push(die);
		}
		table.append(dieRow);
		
		for (i in 1 ... 21) {
			var sureStrikeDieRow = document.createTableRowElement();
			sureStrikeDieRow.classList.add("dice", "roll-2d");
			sureStrikeDice[i] = [null];
			for (k in 1 ... 21) {
				var die = document.createTableCellElement();
				die.width = "5%";
				die.innerHTML = k + "<br>" + i;
				sureStrikeDieRow.append(die);
				sureStrikeDice[i].push(die);
			}
			table.append(sureStrikeDieRow);
		}
		
		var stageRow = document.createTableRowElement();
		stageRow.classList.add("stages");
		for (i in 0 ... Stage.Count) {
			var stage = document.createTableCellElement();
			stage.className = stageClassNames[i];
			stageRow.append(stage);
			stages.push(stage);
		}
		table.append(stageRow);
		
		footnotes = document.createDivElement();
		
		element.append(legend, table, footnotes);
		element.makeFieldSetToggleable();
	}
	public static function create() {
		var table = new RollTable();
		document.getElementById("results").append(table.element);
		return table;
	}
	public function update(bonus:Int, dc:Int, q:RollConfig) {
		var chances = new StageArray(0.);
		function getStage(i:Int) {
			var r = i + bonus;
			var stage = if (r >= dc + 10) {
				Stage.CritSuccess;
			} else if (r >= dc) {
				Stage.Success;
			} else if (r > dc - 10) {
				Stage.Failure;
			} else {
				Stage.CritFailure;
			}
			// nat
			if ((i == 20 || q.keenFlair && i == 19) && stage != CritSuccess) stage++;
			if (i == 1 && stage != CritFailure) stage--;
			return stage;
		}
		var keepHigher = q.rollMode == KeepHigher;
		inline function getStage2(i, k) {
			return getStage((keepHigher ? i > k : i < k) ? i : k);
		}
		if (q.rollTable) {
			table.classList.add("roll-2d");
			for (i in 1 ... 21) {
				for (k in 1 ... 21) {
					var stage = getStage2(i, k);
					chances[stage] += 100/20/20;
					sureStrikeDice[k][i].className = stageClassNames[stage];
				}
			}
		} else {
			table.classList.remove("roll-2d");
			if (q.rollMode != RollOnce) {
				for (i in 1 ... 21) {
					for (k in 1 ... 21) {
						var stage = getStage2(i, k);
						chances[stage] += 100/20/20;
						sureStrikeDice[k][i].className = stageClassNames[stage];
					}
					var stage = getStage(i);
					dice[i].className = stageClassNames[stage];
				}
			} else {
				for (i in 1 ... 21) {
					var stage = getStage(i);
					chances[stage] += 5;
					dice[i].className = stageClassNames[stage];
				}
			}
		}
		//
		if (q.flatChecks != null) {
			for (i => chance in chances) if (i != FlatFailure) {
				var newChance = chance;
				for (flat in q.flatChecks) if (flat > 1) {
					newChance *= (21 - flat) / 20;
				}
				chances[0] += chance - newChance;
				chances[i] = newChance;
			}
		}
		//
		var values = null;
		if (q.efficiencies != null) {
			values = new StageArray(0.);
			for (i => chance in chances) values[i] = chance / 100 * q.efficiencies[i];
		}
		//
		var colSpans = chances.map(chance -> {
			if (chance < 0.01) return 0;
			if (chance < 5) return 1;
			return Math.round(chance / 5);
		});
		var colSpanSum = 0;
		for (n in colSpans) colSpanSum += n;
		if (colSpanSum != 20) {
			var widestStage = 0;
			var widestWidth = colSpans[0];
			for (i => n in colSpans) {
				if (n > widestWidth) {
					widestWidth = n;
					widestStage = i;
				}
			}
			colSpans[widestStage] -= (colSpanSum - 20);
		}
		//
		for (i => chance in chances) {
			if (chance > 0) {
				var stageTD = stages[i];
				stageTD.style.display = "";
				//
				var value = values != null ? values[i] : null;
				var valueStr = value != null ? value.toFixed2() : null;
				//
				var chanceStr = chance + "%";
				var text = chance + "%";
				if (valueStr != null) text += '\n$valueStr';
				//
				if (chances[i] >= 10 || (valueStr == null || valueStr.length <= 2) && chanceStr.length <= 2) {
					stageTD.innerText = text;
					stageTD.removeAttribute("title");
					stageTD.onclick = null;
				} else {
					var short = Math.round(chance) + "%";
					if (short == "0%" && chance > 0) short = "1%";
					if (valueStr != null) {
						short += "\n";
						if (value != 0) {
							short += value < 0 ? "-#" : "+#";
						} else short += "0";
					}
					stageTD.innerText = short;
					stageTD.title = text;
					stageTD.onclick = () -> {
						Browser.window.alert(text);
					};
				}
				stageTD.colSpan = colSpans[i];
			} else {
				stages[i].style.display = "none";
			}
		}
		//
		var title = 'Result';
		if (bonus >= 0) {
			title += ' (+$bonus)';
		} else title += ' ($bonus)';
		var total = 0.;
		if (q.efficiencies != null) {
			for (i in 0 ... Stage.Count) {
				total += chances[i] / 100 * q.efficiencies[i];
			}
		}
		legend.innerText = title;
		//
		var notes = [
			'Any success: ${chances[Success] + chances[CritSuccess]}%',
			'any failure: ${chances[Failure] + chances[CritFailure] + chances[FlatFailure]}%',
		];
		if (q.efficiencies != null) {
			var efficiencyNote = 'efficiency: $total';
			if (q.firstEfficiency != 0) {
				var factor = (total / q.firstEfficiency * 100).toFixed1();
				efficiencyNote += ' ($factor%)';
			}
			notes.push(efficiencyNote);
		}
		footnotes.innerText = notes.join("; ");
		//
		return total;
	}
}

enum abstract Stage(Int) from Int to Int {
	var FlatFailure = 0;
	var CritFailure = 1;
	var Failure = 2;
	var Success = 3;
	var CritSuccess = 4;
	var Count = 5;
}

@:forward
abstract StageArray<T>(Vector<T>) {
	public function new(fill:T) {
		this = new Vector(Stage.Count, fill);
	}
	public var length(get, never):Int;
	inline function get_length() return this.length;
	
	@:arrayAccess inline function get(i:Stage) return this[i];
	@:arrayAccess inline function set(i:Stage, v:T) {
		this[i] = v;
		return v;
	}
	
	public inline function map<R>(fn:T->R):StageArray<R> {
		return cast this.map(fn);
	}
	
	public inline function keyValueIterator() {
		return this.toArray().keyValueIterator();
	}
}