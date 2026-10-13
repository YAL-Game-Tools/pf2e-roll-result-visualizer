package tools;
import js.html.Console;
import js.Browser;
import js.Browser.window;
import js.html.InputElement;
import js.lib.Uint8Array;
import js.lib.Promise;
using StringTools;

class ShareButton {
	public static function decode(type:String, text:String, then:String->Void) {
		switch (type) {
			case "e": {
				then((cast window).decodeURIComponent(text));
			};
			case "b": {
				then(fromBase64(text));
			};
			case "c": {
				var raw = fromBase64(text);
				var bytes = binStringToBytes(raw);
				StringGZ.decompress(bytes).then(then);
			};
		}
	}
	// swap b64 symbols for ones that don't have to be URL-encoded:
	static function toBase64(s:String) {
		s = window.btoa(s);
		s = s.replace("+", "-");
		s = s.replace("/", "_");
		s = s.replace("=", ".");
		return s;
	}
	static function fromBase64(s:String) {
		s = s.replace("-", "+");
		s = s.replace("_", "/");
		s = s.replace(".", "=");
		return window.atob(s);
	}
	static function bytesToBinString(bytes:Uint8Array) {
		var chunks = [];
		final chunkSize = 0x8000;
		var i = 0;
		while (i < bytes.length) {
			var chunk:String = js.Syntax.code('String.fromCharCode.apply(null, {0})', bytes.subarray(i, i + chunkSize));
			chunks.push(chunk);
			i += chunkSize;
		}
		return chunks.join("");
	}
	static function binStringToBytes(s:String) {
		var len = s.length;
		var arr = new Uint8Array(len);
		for (i in 0 ... len) {
			arr[i] = s.charCodeAt(i);
		}
		return arr;
	}
	public static function createSimple<T>(thing:String,
		pre:(then:T->Void)->Void,
		getText:(p:T)->String,
		?button:InputElement
	) {
		var label = "share";
		var labelCopied = "copied!";
		if (button == null) {
			button = Browser.document.createInputElement();
			button.classList.add("share");
			button.type = "button";
			button.value = label;
		} else {
			label = button.value;
			labelCopied = button.dataset.copied ?? labelCopied;
		}
		//
		var revertTimeout:Null<Int> = null;
		function blink() {
			if (revertTimeout != null) Browser.window.clearTimeout(revertTimeout);
			button.value = labelCopied;
			revertTimeout = Browser.window.setTimeout(() -> {
				button.value = label;
			}, 1300);
		}
		//
		button.addEventListener("click", (e) -> {
			pre((param) -> {
				var snip = getText(param);
				function fallback() {
					window.prompt('Here\'s your $thing:', snip);
				}
				try {
					Browser.navigator.clipboard.writeText(snip).then((_) -> {
						blink();
					}).catchError((x) -> {
						Console.error("Failed to copy:", x);
						fallback();
					});
				} catch (x:Dynamic) {
					Console.error("Failed to copy:", x);
					fallback();
				}
			});
		});
		return button;
	}
	public static function create(getText:()->String, getURL:(type:String, data:String)->String, ?button:InputElement) {
		return createSimple("share URL", (then) -> {
			var text = getText();
			var simple:String = (cast window).encodeURIComponent(text);
			var base64 = toBase64(text);
			var bestType = "e", bestText = simple;
			if (base64.length < bestText.length) {
				bestType = "b";
				bestText = base64;
			}
			try {
				StringGZ.compress(text).then((bytes) -> {
					var bb64 = toBase64(bytesToBinString(bytes));
					if (bb64.length < bestText.length) {
						bestType = "c";
						bestText = bb64;
					}
					then({ type: bestType, text: bestText });
				}).catchError((x) -> {
					Console.error("Compression error", x);
					then({ type: bestType, text: bestText });
				});
			} catch (x:Dynamic) {
				Console.error("Compression error", x);
				then({ type: bestType, text: bestText });
			}
		}, (pair) -> {
			return getURL(pair.type, pair.text);
		}, button);
	}
}

@:native("StringGZ")
extern class StringGZ {
	static function compress(str:String):Promise<Uint8Array>;
	static function decompress(bytes:Uint8Array):Promise<String>;
}