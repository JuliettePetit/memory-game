WebAssembly.instantiateStreaming(
  fetch("zig-out/bin/game.wasm"),
  importObject,
).then((result) => {

  const drawBoard = () => {
    result.instance.exports.(
    );
  };

  drawBoard();
});
