const canvas = document.querySelector("canvas");

/* webgpu not supported by browser */
if (!navigator.gpu) {
  canvas.style.cursor = 'crosshair';
  throw new Error("WebGPU not supported on this browser.");
}

/* webgpu supported by browser but not by gpu hardware */
const adapter = await navigator.gpu.requestAdapter(); /* can specify low power or high perf */
if (!adapter) {
  canvas.style.cursor = 'crosshair';
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
const uniformBuffer = device.createBuffer({
  label: "pointer position",
  size:  16, // pos (vec2f) = 2 floats, 8 bytes
  usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
});

/* get pointer position */
let mouseX = 0.5, mouseY = 0.5;
window.addEventListener('pointermove', (e) => {
  mouseX = e.clientX / window.innerWidth;
  mouseY = e.clientY / window.innerHeight;
  device.queue.writeBuffer(uniformBuffer, 0, new Float32Array([mouseX, mouseY, canvas.width, canvas.height]));
});

const cellShaderModule = device.createShaderModule({
  label: "Cell shader",
  code: `
  struct Uniforms {
    cursor_pos: vec2f,
    resolution: vec2f,   // canvas.width, canvas.height in pixels
  };
  @group(0) @binding(0) var<uniform> u: Uniforms;

  @vertex
  fn vertexMain(@builtin(vertex_index) i: u32) -> @builtin(position) vec4f {
    var pos = array<vec2f, 3>(
      vec2f(-1.0, -1.0),
      vec2f( 3.0, -1.0),
      vec2f(-1.0,  3.0)
    );
    return vec4f(pos[i], 0.0, 1.0);
  }

  // apply this to every pixels drawn (set them in red here)
  @fragment
  fn fragmentMain(@builtin(position) fragCoord: vec4f) -> @location(0) vec4f {
    let cursorPixel = vec2f(
      u.cursor_pos.x * u.resolution.x,
      u.cursor_pos.y * u.resolution.y
    );
    let d = fragCoord.xy;
    let cursorHalfSize = 15.0;
    if(d.x < cursorPixel.x + cursorHalfSize && d.x > cursorPixel.x - cursorHalfSize && d.y < cursorPixel.y + cursorHalfSize && d.y > cursorPixel.y - cursorHalfSize){
      return vec4f(1, 0, 0.4, 0.5);
    }
    else{
      return vec4f(1, 0.5, 0.4, 0.5);
    }
  }
  `
});

// render the square
const cursorPipeline = device.createRenderPipeline({
  label: "cursor pipeline",
  layout: "auto",
  vertex: {
    module: cellShaderModule,
    entryPoint: "vertexMain",
  },
  fragment: {
    module: cellShaderModule,
    entryPoint: "fragmentMain",
    targets: [{
      format: canvasFormat
    }]
  }
  });

const bindGroup = device.createBindGroup({
  label: "cursor renderer bind group",
  layout: cursorPipeline.getBindGroupLayout(0),
  entries: [{
    binding: 0,
    resource: { buffer: uniformBuffer }
  }],
});

function draw() {
  const encoder = device.createCommandEncoder();
  const pass = encoder.beginRenderPass({
    colorAttachments: [{
      view: context.getCurrentTexture().createView(),
      loadOp: "clear", // clear between each frame
      clearValue: { r: 0, g: 0, b: 0, a: 0 },
      storeOp: "store",
    }],
  });
  pass.setPipeline(cursorPipeline);
  pass.setBindGroup(0, bindGroup);
  pass.draw(3);
  pass.end();
  // Finish the command buffer and immediately submit it.
  device.queue.submit([encoder.finish()]);
}

function frame() {
  draw();
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
