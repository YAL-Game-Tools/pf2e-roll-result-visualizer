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
	public static var stageClassNames = ["crit-failure", "failure", "success", "crit-success"];
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
			sureStrikeDieRow.classList.add("dice", "sure-strike");
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
		for (i in 0 ... 4) {
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
		var chances:Array<Float> = [0, 0, 0, 0];
		inline function getStage(i:Int) {
			var r = i + bonus;
			var stage = if (r >= dc + 10) {
				3;
			} else if (r >= dc) {
				2;
			} else if (r > dc - 10) {
				1;
			} else {
				0;
			}
			// nat
			if (i == 20 && stage < 3) stage++;
			if (i == 1 && stage > 0) stage--;
			return stage;
		}
		if (q.sureStrike == Grid) {
			table.classList.add("sure-strike");
			for (i in 1 ... 21) {
				for (k in 1 ... 21) {
					var stage = getStage(i > k ? i : k);
					chances[stage] += 100/20/20;
					sureStrikeDice[k][i].className = stageClassNames[stage];
				}
			}
		} else {
			table.classList.remove("sure-strike");
			if (q.sureStrike == On) {
				for (i in 1 ... 21) {
					for (k in 1 ... 21) {
						var stage = getStage(i > k ? i : k);
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
		var values = if (q.efficiencies != null) {
			[for (i in 0 ... 4) chances[i] / 100 * q.efficiencies[i]];
		} else null;
		//
		for (i in 0 ... 4) {
			var chance = chances[i];
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
				stageTD.colSpan = Std.int(chance / 5);
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
			for (i in 0 ... 4) {
				total += chances[i] / 100 * q.efficiencies[i];
			}
		}
		legend.innerText = title;
		//
		var notes = [
			'Any success: ${chances[2] + chances[3]}%',
			'any failure: ${chances[0] + chances[1]}%',
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
