package damage;

import js.html.KeyboardEvent;
import js.html.svg.Element;
import js.html.SpanElement;
import js.html.LegendElement;
import js.html.DivElement;
import js.html.TextAreaElement;
import js.html.FieldSetElement;

class DamageFormula {
	public var fieldSet:FieldSetElement;
	public var legend:LegendElement;
	public var legendText:SpanElement;
	public var field:TextAreaElement;
	/** the whole bottom bar **/
	public var under:DivElement;
	/** holds [=] value[1-6, 3.5 avg] [➜] ratio[100%] **/
	public var result:DivElement;
	public var value:SpanElement;
	public var ratio:SpanElement;
	public var range = new txr.Range(0, 0);
	//
	public var label(get, set):String;
	inline function get_label() return legendText.innerText;
	inline function set_label(s) return legendText.innerText = s;
	//
	public var formula(get, set):String;
	inline function get_formula() return field.value;
	inline function set_formula(s) return field.value = s;
	//
	public static function ofElement(e:Element):DamageFormula {
		return (cast e).yalDamageFormula;
	}
	public function new() {
		fieldSet = document.createFieldSetElement();
		fieldSet.classList.add("damage-formula");
		(cast fieldSet).yalDamageFormula = this;
		
		//
		legend = document.createLegendElement();
		legendText = document.createSpanElement();
		legendText.contentEditable = "plaintext-only";
		legendText.append("New Roll");
		legend.append(legendText);
		fieldSet.append(legend);
		
		//
		field = document.createTextAreaElement();
		field.placeholder = "1d8+4";
		field.rows = 1;
		fieldSet.append(field);
		
		//
		value = document.createSpanElement();
		ratio = document.createSpanElement();
		
		//
		result = document.createDivElement();
		result.classList.add("result");
		result.appendMixed("= ", value, " ➜ ", ratio);
		
		//
		under = document.createDivElement();
		under.append(result);
		fieldSet.append(under);
		
		//
		function addButton(text, title, onClick) {
			var button = document.createInputElement();
			button.type = "button";
			button.value = text;
			button.onclick = onClick;
			button.title = title;
			legend.append(button);
			return button;
		}
		addButton("↑", "Move up", () -> {
			var prev = fieldSet.previousElementSibling;
			if (prev != null) prev.before(fieldSet);
		});
		addButton("↓", "Move down", () -> {
			var next = fieldSet.nextElementSibling;
			if (next != null) next.after(fieldSet);
		});
		addButton("D", "Duplicate", () -> {
			var copy = new DamageFormula();
			fieldSet.after(copy.fieldSet);
			copy.setTo(this);
		});
		addButton("X", "Delete", () -> {
			fieldSet.remove();
		});
		//
		field.addEventListener("change", e -> {
			update();
		});
		/*field.addEventListener("keydown", (e:KeyboardEvent) -> {
			if (e.key == "Enter") update();
		});*/
	}
	
	public function setTo(q:DamageFormula) {
		label = q.label;
		formula = q.formula;
		var h = q.field.style.height;
		if (h != "") field.style.height = h;
		autoSize();
		update();
	}
	public function autoSize() {
		field.rows = formula.split("\n").length;
	}
	public function update() {
		var text = StringTools.trim(field.value);
		range = text != "" ? txr.TxrProgram.eval(text) : new txr.Range(0, 0);
		if (range != null) {
			field.classList.remove("error");
			field.title = "";
			value.innerText = range.toStringAvg();
		} else {
			field.classList.add("error");
			field.title = txr.TxrProgram.evalError;
		}
		RollCalcApp.updateRatios();
	}
}