import haxe.ds.Vector;
import js.html.TableElement;
import js.Browser;
import js.Browser.document;
import js.html.Element;
import RollTable;
using HtmlTools;

class MultiHit {
	static var element:Element = document.getElementById("multi-out");
	static var chancesPerAttempt:Array<StageArray<Float>>;
	static var attempts:Int;
	static var table:TableElement;
	static var results:Array<MultiHitResult>;
	static var chancesPerSuccessCount:Array<Float>;
	static var anyCritHits = 0.;
	static var hitsOnAverage = 0.;
	public static var useTable = false;
	public static var latest:MultiHitResults = null;
	public static var stored:MultiHitResults = null;
	static function calcRec(attempt:Int, chance:Float) {
		if (attempt >= attempts) {
			var tr:Element;
			if (useTable) {
				tr = document.createTableRowElement();
				tr.classList.add("stages");
			} else tr = null;
			var successes = 0;
			var hasCritHits = false;
			for (result in results) {
				if (result.stage.isSuccess()) successes += 1;
				if (result.stage == CritSuccess) hasCritHits = true;
				//
				if (useTable) {
					var td = document.createTableCellElement();
					td.classList.add(RollTable.stageClassNames[result.stage]);
					td.append(result.chance.toPercent());
					tr.append(td);
				}
			}
			chancesPerSuccessCount[successes] += chance;
			if (hasCritHits) anyCritHits += chance;
			hitsOnAverage += successes * chance / 100;
			//
			if (useTable) {
				var td = document.createTableCellElement();
				td.classList.add("left");
				td.append(chance.toPercent());
				tr.append(td);
				//
				table.append(tr);
			}
			return;
		}
		var chances = chancesPerAttempt[attempt];
		var result = results[attempt];
		for (stage => stageChance in chances) {
			if (stageChance <= 0) continue;
			result.chance = stageChance;
			result.stage = stage;
			calcRec(attempt + 1, chance * stageChance / 100);
		}
	}
	public static function calc(_chances) {
		chancesPerAttempt = _chances;
		attempts = chancesPerAttempt.length;
		element.innerHTML = "";
		if (useTable) {
			table = document.createTableElement();
			table.classList.add("results");
			var headRow = document.createTableRowElement();
			function addHeadRow(s:String) {
				var th = document.createElement("th");
				th.append(s);
				headRow.append(th);
				return th;
			}
			for (i in 0 ... chancesPerAttempt.length) {
				addHeadRow("" + (i + 1));
			}
			addHeadRow("Chance").classList.add("left");
			table.append(headRow);
		} else table = null;
		//
		results = [for (i in 0 ... attempts) new MultiHitResult()];
		chancesPerSuccessCount = [for (i in 0 ... attempts + 1) 0];
		anyCritHits = 0;
		hitsOnAverage = 0;
		calcRec(0, 100);
		//
		if (useTable) element.append(table);
		//
		var ul = document.createUListElement();
		function addChance(text:String) {
			var li = document.createLIElement();
			li.append(text);
			ul.append(li);
			return li;
		}
		var anyHits = 0.;
		for (count => chance in chancesPerSuccessCount) {
			if (chance > 0) {
				var snip:String;
				if (count != 0) {
					snip = count + " success";
					if (count != 1) snip += "es";
				} else snip = "No successes";
				snip += ': ${chance.toPercent()}';
				if (stored != null && count < stored.chancesPerSuccessCount.length) {
					snip += ' (vs ${stored.chancesPerSuccessCount[count].toPercent()})';
				}
				addChance(snip);
			}
			if (count > 0) anyHits += chance;
		}
		if (anyHits > 0 && attempts > 1) {
			var snip = 'Any successes: ${anyHits.toPercent()}';
			if (stored != null) snip += ' (vs ${stored.anyHits.toPercent()})';
			addChance(snip);
		}
		if (anyCritHits > 0) {
			var snip = 'Any critical successes: ${anyCritHits.toPercent()}';
			if (stored != null) snip += ' (vs ${stored.anyCritHits.toPercent()})';
			addChance(snip);
		}
		{
			var snip = "Successes on average: " + hitsOnAverage.toFixed2();
			if (stored != null) snip += ' (vs ${stored.hitsOnAverage.toFixed2()})';
			addChance(snip);
		}
		//
		latest = new MultiHitResults();
		latest.chancesPerSuccessCount = chancesPerSuccessCount;
		latest.anyHits = anyHits;
		latest.anyCritHits = anyCritHits;
		latest.hitsOnAverage = hitsOnAverage;
		//
		element.append(ul);
	}
	public static function clear() {
		element.innerHTML = "";
	}
}
class MultiHitResults {
	public var chancesPerSuccessCount:Array<Float> = [];
	public var anyHits = 0.;
	public var anyCritHits = 0.;
	public var hitsOnAverage = 0.;
	public function new() {
		
	}
}
class MultiHitResult {
	public var stage = Stage.FlatFailure;
	public var chance = 0.;
	public function new() {
		
	}
}