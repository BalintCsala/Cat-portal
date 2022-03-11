#version 150

#moj_import <matrix.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

uniform float GameTime;
uniform int EndPortalLayers;
uniform vec2 ScreenSize;

in vec4 texProj0;
const float PI = 3.141592654;

const float NYAN_SPEED = 10.0;
const float NYAN_SIZE = 7.0;

const vec3 BACKGROUND_COLOR = vec3(0.022087, 0.098399, 0.110818);
const vec3 LAYER1 = vec3(0.080955, 0.314821, 0.661491);
const vec3 LAYER2 = vec3(0.204675, 0.390010, 0.302066);
const vec3 LAYER3 = vec3(0.047281, 0.315338, 0.321970);
const vec3 LAYER4 = vec3(0.196766, 0.142899, 0.214696);
const vec3 LAYER5 = vec3(0.070006, 0.243332, 0.235792);
const vec3 LAYER6 = vec3(0.133516, 0.138278, 0.148582);
const vec3 LAYER7 = vec3(0.097721, 0.110188, 0.187229);

const vec3[] COLORS = vec3[](
    vec3(0.022087, 0.098399, 0.110818),
    vec3(0.011892, 0.095924, 0.089485),
    vec3(0.027636, 0.101689, 0.100326),
    vec3(0.046564, 0.109883, 0.114838),
    vec3(0.064901, 0.117696, 0.097189),
    vec3(0.063761, 0.086895, 0.123646),
    vec3(0.084817, 0.111994, 0.166380),
    vec3(0.097489, 0.154120, 0.091064),
    vec3(0.106152, 0.131144, 0.195191),
    LAYER7,
    LAYER6,
    LAYER5,
    LAYER4,
    LAYER3, 
    LAYER2,
    LAYER1
);

const mat4 SCALE_TRANSLATE = mat4(
    0.5, 0.0, 0.0, 0.25,
    0.0, 0.5, 0.0, 0.25,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0
);

mat4 end_portal_layer(float layer) {
    mat4 translate = mat4(
        1.0, 0.0, 0.0, (2.0 + layer / 1.5) * (-GameTime * NYAN_SPEED),
        0.0, 1.0, 0.0, 17.0 / layer,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    mat2 rotate = mat2_rotate_z(radians((layer * layer * 4321.0 + layer * 9.0) * 2.0));

    mat2 scale = mat2((4.5 - layer / 4.0) * 2.0);

    return mat4(scale * rotate) * translate * SCALE_TRANSLATE;
}

const float GRID_SIZE = 0.1;

vec3 hash3(uint n) {
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n * 16807U,n * 48271U);
    return vec3( k & uvec3(0x7fffffffU)) / float(0x7fffffff);
}


vec2 getCellPoint(ivec2 cell) {
    cell += 1000;
    uint n = uint(cell.y * 10000 + cell.x);
    return hash3(n).xy * 0.8 + 0.1;
}

vec2 getCellUV(vec2 uv) {
    uv /= GRID_SIZE;
    ivec2 cell = ivec2(floor(uv));
    
    float minDist = 2000.0;
    vec2 cellUV;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            ivec2 coord = cell + ivec2(x, y);
            vec2 pos = vec2(coord) + getCellPoint(coord);
            float dist = distance(pos, uv);
            if (dist < minDist) {
                minDist = dist;
                cellUV = uv - pos;
            }
        }
    }
    return cellUV;
}

out vec4 fragColor;

const vec3[] RAINBOW = vec3[](
	vec3(1, 0, 0),
	vec3(1, 0.6, 0),
	vec3(1, 1, 0),
	vec3(0.2, 1, 0),
	vec3(0, 0.6, 1),
	vec3(0.4, 0.2, 1)
);

void main() {
    vec3 color = BACKGROUND_COLOR;
    for (int i = 0; i < EndPortalLayers; i++) {
		vec4 projCoord = texProj0;
		projCoord.y *= ScreenSize.y / ScreenSize.x;
		projCoord *= end_portal_layer(float(i + 1));
		
		vec2 uv = projCoord.xy / projCoord.w;
		vec2 cellUV = getCellUV(uv);
		cellUV.y *= -1;
		cellUV *= NYAN_SIZE;
		if (cellUV.x > 2.0 || cellUV.y < 0.0 || cellUV.y > 1.0)
			continue;
		
		vec2 uvOffs = vec2(floor(GameTime * 10000.0) / 6.0, 0);
		vec4 col = texture(Sampler1, cellUV * vec2(1.0 / 12.0, 1) + uvOffs);
        if (cellUV.x < 0.0 || cellUV.x < 0.4 && col.a < 0.1) {
			int index = int(cellUV.y * 7.0) - int(floor(cellUV.x / 0.6 + floor(GameTime * 5000.0))) % 2;
			if (index < 0 || index > 5)
				continue;
			color = mix(color, RAINBOW[index], clamp((cellUV.x + 2.0) / 2.0, 0, 1));
		} else if (col.a < 0.1) {
			continue;
		} else {
			color = col.rgb;
		}
			
	}
    fragColor = vec4(color, 1.0);
}
