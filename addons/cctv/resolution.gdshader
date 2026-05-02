// taken from https://godotshaders.com/shader/realistic-jpeg-artifacting/ and modified
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform int quality : hint_range(1, 100) = 8;
uniform int block_size : hint_range(2, 64, 2) = 8;

uniform float noise_scale = 2.0;
uniform float noise_strength = 0.7;
uniform float time_speed = 0.01; // optional animation

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// colorspace conversions
vec3 rgb_to_ycbcr(vec3 c) {
    float y =  0.299000 * c.r + 0.587000 * c.g + 0.114000 * c.b;
    float cb = -0.168736 * c.r - 0.331264 * c.g + 0.500000 * c.b + 0.5;
    float cr =  0.500000 * c.r - 0.418688 * c.g - 0.081312 * c.b + 0.5;
    return vec3(y, cb, cr);
}

vec3 ycbcr_to_rgb(vec3 c) {
    float y  = c.x;
    float cb = c.y - 0.5;
    float cr = c.z - 0.5;
    float r = y + 1.402000 * cr;
    float g = y - 0.344136 * cb - 0.714136 * cr;
    float b = y + 1.772000 * cb;
    return vec3(r, g, b);
}

void fragment() {
    const int N = 8; // dct size
    // orthogonal dct basis, constants from https://patents.google.com/patent/CN100409693C/en
    const float dct[64] = float[64](
        0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,0.353553,
        0.490393,0.415735,0.277785,0.0975452,-0.0975452,-0.277785,-0.415735,-0.490393,
        0.46194,0.191342,-0.191342,-0.46194,-0.46194,-0.191342,0.191342,0.46194,
        0.415735,-0.0975452,-0.490393,-0.277785,0.277785,0.490393,0.0975452,-0.415735,
        0.353553,-0.353553,-0.353553,0.353553,0.353553,-0.353553,-0.353553,0.353553,
        0.277785,-0.490393,0.0975452,0.415735,-0.415735,-0.0975452,0.490393,-0.277785,
        0.191342,-0.46194,0.46194,-0.191342,-0.191342,0.46194,-0.46194,0.191342,
        0.0975452,-0.277785,0.415735,-0.490393,0.490393,-0.415735,0.277785,-0.0975452
    );

    // flattened 8x8 buffers
    vec3 block[64];
    vec3 horiz[64];
    vec3 vert[64];
    vec3 inv_horiz[64];
    vec3 inv_block[64];

    // get viewport size from SCREEN_PIXEL_SIZE
    vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;

    // pixel coords
    vec2 px_f = SCREEN_UV * viewport_size;
    int px = int(floor(px_f.x));
    int py = int(floor(px_f.y));

    float size_noise = hash(vec2(float(px / block_size), float(py / block_size)) * noise_scale);
    int bs = int(clamp(
        float(block_size) * mix(0.5, 2.0, size_noise),
        2.0,
        64.0
    ));
    int block_origin_x = (px / bs) * bs;
    int block_origin_y = (py / bs) * bs;
    int lid_x = px - block_origin_x;
    int lid_y = py - block_origin_y;

    for (int y = 0; y < N; y++) {
        for (int x = 0; x < N; x++) {
            float fx = (float(x) + 0.5) / float(N);
            float fy = (float(y) + 0.5) / float(N);
            int sample_x = block_origin_x + int(floor(fx * float(bs)));
            int sample_y = block_origin_y + int(floor(fy * float(bs)));
            sample_x = clamp(sample_x, 0, int(viewport_size.x) - 1);
            sample_y = clamp(sample_y, 0, int(viewport_size.y) - 1);
			vec2 uv = (vec2(float(sample_x), float(sample_y)) + vec2(0.5)) / viewport_size;
            vec3 texc = texture(SCREEN_TEXTURE, uv).rgb;
            block[y * N + x] = rgb_to_ycbcr(texc);
        }
    }

    for (int y = 0; y < N; y++) {
        for (int u = 0; u < N; u++) {
            vec3 sum = vec3(0.0);
            for (int x = 0; x < N; x++) {
                sum += block[y * N + x] * dct[u * N + x];
            }
            horiz[y * N + u] = sum;
        }
    }

    vec2 block_coord = vec2(float(block_origin_x), float(block_origin_y)) * noise_scale;

    // stable block noise
    float n = hash(block_coord + TIME * time_speed);

    // remap noise around 1.0
    float noise_factor = mix(
        1.0 - noise_strength,
        1.0 + noise_strength,
        n
    );

    float qscale = max(1.0, float(quality) * noise_factor);
    for (int v = 0; v < N; v++) {
        for (int u = 0; u < N; u++) {
            vec3 sum = vec3(0.0);
            for (int y = 0; y < N; y++) {
                sum += horiz[y * N + u] * dct[v * N + y];
            }
            float q = qscale * float(u + v + 1);
            vert[v * N + u] = round(sum * 128.0 / q) * (q / 128.0);
        }
    }

    for (int v = 0; v < N; v++) {
        for (int x = 0; x < N; x++) {
            vec3 sum = vec3(0.0);
            for (int u = 0; u < N; u++) {
                sum += vert[v * N + u] * dct[u * N + x];
            }
            inv_horiz[v * N + x] = sum;
        }
    }

    for (int y = 0; y < N; y++) {
        for (int x = 0; x < N; x++) {
            vec3 sum = vec3(0.0);
            for (int v = 0; v < N; v++) {
                sum += inv_horiz[v * N + x] * dct[v * N + y];
            }
            inv_block[y * N + x] = sum;
        }
    }

    int pick_x = int(float(lid_x) * float(N) / float(bs));
    int pick_y = int(float(lid_y) * float(N) / float(bs));
    pick_x = clamp(pick_x, 0, N - 1);
    pick_y = clamp(pick_y, 0, N - 1);

    vec3 out_ycbcr = inv_block[pick_y * N + pick_x];
    vec3 out_rgb = ycbcr_to_rgb(out_ycbcr);
    COLOR = vec4(clamp(out_rgb, 0.0, 1.0), 1.0);
}