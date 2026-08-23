struct VertexInput {
    @location(0) position: vec3<f32>,
};

@vertex
fn vs_main(input: VertexInput) -> @builtin(position) vec4<f32> {
    return vec4<f32>(input.position, 1.0);
}

struct Uniforms {
    cursors_pos: array<vec4f, 2>,
    resolution: vec2f,   // canvas.width, canvas.height in pixels
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
    var total_influence = 0.0;
    for (var i = 0u; i < 2u; i++) {
        let center1 = vec2f(
            u.cursors_pos[i].xy.x,
            u.cursors_pos[i].xy.y
        ) * u.resolution;
        let center2 = vec2f(
            u.cursors_pos[i].zw.x,
            u.cursors_pos[i].zw.y
        ) * u.resolution;
        let p = fragCoord.xy; // current pixel
        let radius = 15.0;
        let d1 = dot(p - center1, p - center1); //dot(v, v) is identical to |v|² (the squared length)
        let d2 = dot(p - center2, p - center2);
        let r2 = radius * radius;
        let influence1 = r2 / d1;
        let influence2 = r2 / d2;
        total_influence += influence1 + influence2;
    }
    let threshold = 1.0;
    let softness = 0.1;
    let alpha = smoothstep(threshold - softness, threshold + softness, total_influence);
    let rgb = vec3f(1, 0, 0.4) * (alpha); // premultiply manually
    return vec4f(rgb, alpha);
}
