const canvas = document.getElementById("pointer-canvas");

/* webgpu not supported by browser */
if (!navigator.gpu) {
  canvas.style.cursor = "crosshair";
  throw new Error("WebGPU not supported on this browser.");
}

/* webgpu supported by browser but not by gpu hardware */
const adapter =
  await navigator.gpu.requestAdapter(); /* can specify low power or high perf */
if (!adapter) {
  canvas.style.cursor = "crosshair";
  throw new Error("No appropriate GPUAdapter found.");
}
const device = await adapter.requestDevice();

canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

const context = canvas.getContext("webgpu");
const canvasFormat = navigator.gpu.getPreferredCanvasFormat();
context.configure({
  device: device,
  format: canvasFormat,
  alphaMode: "premultiplied",
});

/* create the uniform buffer that correspond */
const TRAIL_LENGTH = 8;
const uniformBuffer = device.createBuffer({
  label: "pointer position",
  size: 80, // 64 (4×vec4f) + 8 (vec2f) = 72, padded up to nearest multiple of 16
  usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
});

/* get pointer position & create trail positions */
let trail = Array.from({ length: TRAIL_LENGTH }, () => [0.5, 0.5]);
let pointer = { x: 0.5, y: 0.5 };
window.addEventListener("pointermove", (e) => {
  pointer.x = e.clientX / window.innerWidth;
  pointer.y = e.clientY / window.innerHeight;
});

function updateUniform() {
  // shift everything back, insert new position at front
  trail.pop();
  trail.unshift([pointer.x, pointer.y]);
  device.queue.writeBuffer(
    uniformBuffer,
    0,
    new Float32Array(trail.flat().concat(canvas.width).concat(canvas.height)),
  );
}

async function loadShader(path) {
  const res = await fetch(path);
  return res.text();
}

const shaderCode = await loadShader("./shader.wgsl");
const shaderModule = device.createShaderModule({
  label: "pointer shader",
  code: shaderCode,
});

// render the square
const cursorPipeline = device.createRenderPipeline({
  label: "cursor pipeline",
  layout: "auto",
  vertex: {
    module: shaderModule,
    entryPoint: "vertexMain",
  },
  fragment: {
    module: shaderModule,
    entryPoint: "fragmentMain",
    targets: [
      {
        format: canvasFormat,
      },
    ],
  },
});

const bindGroup = device.createBindGroup({
  label: "cursor renderer bind group",
  layout: cursorPipeline.getBindGroupLayout(0),
  entries: [
    {
      binding: 0,
      resource: { buffer: uniformBuffer },
    },
  ],
});

function draw() {
  const encoder = device.createCommandEncoder();
  const pass = encoder.beginRenderPass({
    colorAttachments: [
      {
        view: context.getCurrentTexture().createView(),
        loadOp: "clear", // clear between each frame
        clearValue: { r: 0, g: 0, b: 0, a: 0 },
        storeOp: "store",
      },
    ],
  });
  pass.setPipeline(cursorPipeline);
  pass.setBindGroup(0, bindGroup);
  pass.draw(3);
  pass.end();
  // Finish the command buffer and immediately submit it.
  device.queue.submit([encoder.finish()]);
}

function frame() {
  updateUniform();
  draw();
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
