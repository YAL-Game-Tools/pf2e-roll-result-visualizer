// https://evanhahn.com/javascript-compression-streams-api-with-strings/
class StringGZ {
	/**
	 * Convert a string to its UTF-8 bytes and compress it.
	 *
	 * @param {string} str
	 * @returns {Promise<Uint8Array>}
	 */
	static async compress(str) {
		// Convert the string to a byte stream.
		const stream = new Blob([str]).stream();

		// Create a compressed stream.
		const compressedStream = stream.pipeThrough(
			new CompressionStream("gzip")
		);

		// Read all the bytes from this stream.
		const chunks = [];
		for await (const chunk of compressedStream) {
			chunks.push(chunk);
		}
		return await StringGZ.concatUint8Arrays(chunks);
	}
	
	/**
	 * Decompress bytes into a UTF-8 string.
	 *
	 * @param {Uint8Array} compressedBytes
	 * @returns {Promise<string>}
	 */
	static async decompress(compressedBytes) {
		// Convert the bytes to a stream.
		const stream = new Blob([compressedBytes]).stream();

		// Create a decompressed stream.
		const decompressedStream = stream.pipeThrough(
			new DecompressionStream("gzip")
		);

		// Read all the bytes from this stream.
		const chunks = [];
		for await (const chunk of decompressedStream) {
			chunks.push(chunk);
		}
		const stringBytes = await StringGZ.concatUint8Arrays(chunks);

		// Convert the bytes to a string.
		return new TextDecoder().decode(stringBytes);
	}
	
	/**
	 * Combine multiple Uint8Arrays into one.
	 *
	 * @param {ReadonlyArray<Uint8Array>} uint8arrays
	 * @returns {Promise<Uint8Array>}
	 */
	static async concatUint8Arrays(uint8arrays) {
		const blob = new Blob(uint8arrays);
		const buffer = await blob.arrayBuffer();
		return new Uint8Array(buffer);
	}
}