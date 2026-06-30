const colorNames = [
  "angelcat",
  "blackbandaid",
  "blackpill",
  "bomb",
  "cutter",
  "demoncat",
  "dva",
  "error404",
  "glock",
  "jirai",
  "purpbandaid",
  "purpbunny",
  "purppill",
  "whitebunny",
];

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

  let gamePtr = null;
  let cardsPtr = null;
  const cols = 4;
  const rows = 4;
  let locked = false;

  const displayCard = (i, color) => {
    img = document.getElementById(`card-${i}`);
    img.src = `res/img/${colorNames[color]}.png`;
  };

  const hideCards = () => {
    const hiddenPtr = wasm.getHiddenCards(gamePtr);
    const hiddenMem = new Uint8Array(wasm.memory.buffer);
    for (let i = 0; i < cols * rows; i++) {
      if (hiddenMem[hiddenPtr + i] === 1) {
        const img = document.getElementById(`card-${i}`);
        img.src = "res/img/hidden.jpg";
      }
    }
  };

  const onCardClick = (index, color) => {
    if (locked) return;
    const result = wasm.selectCard(gamePtr, index);

    displayCard(index, color);

    if (result === 0) {
      locked = true;
      setTimeout(() => {
        hideCards();
        locked = false;
      }, 1000);
    }
  };

  const drawBoard = () => {
    gamePtr = wasm.init(cols * rows);
    cardsPtr = wasm.getCards(gamePtr);
    const mem = new Uint32Array(wasm.memory.buffer);

    const baseIndex = cardsPtr / 4;

    const container = document.createElement("div");
    container.id = "cardGrid";
    container.classList.add("container");
    document.body.appendChild(container);

    for (let i = 0; i < cols * rows; i++) {
      const color = mem[baseIndex + i];
      console.log(cardsPtr, color);

      const div = document.createElement("div");
      container.appendChild(div);

      const img = document.createElement("img");

      img.src = "res/img/hidden.jpg";
      img.id = `card-${i}`;
      img.addEventListener("click", () => onCardClick(i, color));
      div.appendChild(img);
    }
  };

  drawBoard();
});
