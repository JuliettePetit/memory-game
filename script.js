const importObject = {
  env: {
    jsSeed: () => BigInt(Date.now()),
  },
};

WebAssembly.instantiateStreaming(
  fetch("zig-out/bin/game.wasm"),
  importObject,
).then((result) => {
  const wasm = result.instance.exports;
  wasm.seedRng();
  const drawBoard = () => {
    const cols = 4;
    const rows = 4;
    const gamePtr = wasm.init(cols * rows);
    const cardsPtr = wasm.getCards(gamePtr);
    const mem = new Uint32Array(wasm.memory.buffer);

    const baseIndex = cardsPtr / 4;
    for (var i = 0; i < cols * rows; i++) {
      console.log(cardsPtr, mem[baseIndex + i]);
    }

    console.log(gamePtr);
  };

  drawBoard();
});
