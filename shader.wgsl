struct VertexInput {
    @location(0) position: vec3<f32>,
};

@vertex
fn vs_main(input: VertexInput) -> @builtin(position) vec4<f32> {
    return vec4<f32>(input.position, 1.0);
}

struct Uniforms {
    cursors_pos: array<vec4f, 4>,
    resolution: vec2f,   // canvas.width, canvas.height in pixels
    time: f32,
};
@group(0) @binding(0) var<uniform> u: Uniforms;

@vertex
fn vertexMain(@builtin(vertex_index) i: u32) -> @builtin(position) vec4f {
    var pos = array<vec2f, 3>(
        vec2f(-1.0, -1.0),
        vec2f(3.0, -1.0),
        vec2f(-1.0, 3.0)
    );
    return vec4f(pos[i], 0.0, 1.0);
}

// apply this to every pixels drawn (covering the whole window here)
@fragment
fn fragmentMain(@builtin(position) fragCoord: vec4f) -> @location(0) vec4f {
    //metaball
    var total_influence = 0.0;
    let p = fragCoord.xy; // current pixel

    let noiseScale = 0.02;   // how zoomed in the noise pattern is
    let wobbleStrength = 15.0;
    let n = noise(p * noiseScale + vec2f(u.time , 0.0)); // the noise value for this pixel (in [0,1])
    let wobble = (n - 0.5) * wobbleStrength; // center around 0, scale to pixels

    let pWarped = p + vec2f(wobble, wobble); // displaced sampling position

    let radius = 10.0;
    let r2 = radius * radius;
    for (var i = 0u; i < 2u; i++) {
        let center1 = vec2f(u.cursors_pos[i].xy) * u.resolution;
        let center2 = vec2f(u.cursors_pos[i].zw) * u.resolution;
        let d1 = dot(pWarped - center1, pWarped - center1); //dot(v, v) is identical to |v|² (the squared length) it's less expensive
        let d2 = dot(pWarped - center2, pWarped - center2);
        let influence1 = r2 / d1;
        let influence2 = r2 / d2;
        total_influence += influence1 + influence2;
    }
    let threshold = 1.0;
    let softness = 0.99;
    let alpha = smoothstep(threshold - softness, threshold + softness, total_influence);
    let rgb = vec3f(1, 0, 0.4) * (alpha); // premultiply manually
    return vec4f(rgb, alpha);

    return vec4f(1, 0, 0.4, 0);
}

fn noise(x: vec2f) -> f32 {
    let i = floor(x);  // integer
    let f = fract(x);  // fraction
    // Four corners in 2D of a tile
    let a = rand2d(i);
    let b = rand2d(i + vec2(1.0, 0.0));
    let c = rand2d(i + vec2(0.0, 1.0));
    let d = rand2d(i + vec2(1.0, 1.0));
    let u = f * f * (3.0 - 2.0 * f); // custom cubic curve (Hermine)
    return mix(a, b, u.x) +
                (c - a) * u.y * (1.0 - u.x) +
                (d - b) * u.x * u.y;
}

fn rand2d(st: vec2f) -> f32 {
    return fract(sin(dot(st.xy,
        vec2f(12.9898, 78.233))) *
        43758.5453123);
}

fn rand(x: f32) -> f32 {
    return fract(sin(x) * 1.0);
}
