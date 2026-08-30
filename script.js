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

DOT_SIZE = 14;

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
    const img = document.getElementById(`card-${i}`);
    img.src = `res/img/${colorNames[color]}.png`;
  };

  const hideCards = () => {
    const hiddenPtr = wasm.getHiddenCards(gamePtr);
    const hiddenMem = new Uint8Array(wasm.memory.buffer);
    for (let i = 0; i < cols * rows; i++) {
      if (hiddenMem[hiddenPtr + i] !== 0) {
        const img = document.getElementById(`card-${i}`);
        img.src = "res/img/hidden.jpg";
      }
    }
  };

  let startTime = null;
  let timerInterval = null;

  const startTimer = () => {
    startTime = Date.now();
    timerInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - startTime) / 1000);
      const minutes = Math.floor(elapsed / 60);
      const seconds = elapsed % 60;
      wasm.updateClock(minutes, seconds);
      displayTimer();
    }, 1000);
  };

  const stopTimer = () => {
    clearInterval(timerInterval);
    return Math.floor((Date.now() - startTime) / 1000);
  };

  const showWinScreen = () => {
    const elapsed = stopTimer();
    console.log("elapsed", elapsed);
    document.getElementById("win-text").textContent =
      `you cleared the board in ${elapsed} second`;
    document.getElementById("win-screen-wrapper").style.display = "flex";
  };

  const onCardClick = (index, color) => {
    if (locked) return;
    const result = wasm.selectCard(gamePtr, index);

    displayCard(index, color);

    if (result === 2 && wasm.gameEnd(gamePtr)) {
      showWinScreen();
    }

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

    const existing = document.getElementById("cardGrid");
    if (existing) existing.remove();
    const container = document.createElement("div");
    container.id = "cardGrid";
    container.classList.add("container");
    document.getElementById("game-layout").appendChild(container);

    for (let i = 0; i < cols * rows; i++) {
      const color = mem[baseIndex + i];

      const div = document.createElement("div");
      container.appendChild(div);

      const img = document.createElement("img");

      img.src = "res/img/hidden.jpg";
      img.id = `card-${i}`;
      img.addEventListener("click", () => onCardClick(i, color));
      div.appendChild(img);
    }
  };

  const displayTimer = () => {
    const buffer = new Uint8Array(wasm.memory.buffer, timerPtr, bufferSize);
    console.log(buffer);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (let x = 0; x < 21; x++) {
      for (let y = 0; y < 5; y++) {
        const isOn = buffer[y * 21 + x];
        if (isOn) {
          ctx.shadowColor = "#d726ff";
          ctx.shadowBlur = 8;
          ctx.fillStyle = "#e8b3ff";
        } else {
          ctx.shadowBlur = 0;
          ctx.fillStyle = "#2a2a2a";
        }
        ctx.beginPath();
        ctx.arc(
          x * DOT_SIZE + DOT_SIZE / 2,
          y * DOT_SIZE + DOT_SIZE / 2,
          5,
          0,
          Math.PI * 2,
        );
        ctx.fill();
      }
    }
  };

  drawBoard();

  timerPtr = wasm.getBufferPtr();
  bufferSize = wasm.getBufferLen();
  const canvas = document.getElementById("timerCanvas");
  const ctx = canvas.getContext("2d");

  startTimer();
});
