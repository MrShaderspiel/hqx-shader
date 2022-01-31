#version 130

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform sampler2D colortex4;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

#define MX 1.1 // start smoothing wt.
#define K -1.1 // wt. decrease factor
#define MAX_W 0.75 // max filter weigth
#define MIN_W 0.03 // min filter weigth
#define LUM_ADD 0.33 // effects smoothing

#define STAGES 2

void main() {
	vec4 color = texture2D(texture, texcoord);
	vec3 c = color.xyz;
	
	float x = 1.0 / textureSize(texture, 0).x;
	float y = 1.0 / textureSize(texture, 0).y;

	const vec3 dt = 1.0 * vec3(1.0, 1.0, 1.0);

	for(int i = 0; i <= STAGES; i++) {

		vec2 dg1 = vec2( x, y) / STAGES;
		vec2 dg2 = vec2(-x, y) / STAGES;
		
		vec2 sd1 = dg1 * 0.5;
		vec2 sd2 = dg2 * 0.5;
		
		vec2 ddx = vec2(x, 0.0);
		vec2 ddy = vec2(0.0, y);
		
		vec4 t1 = vec4(texcoord - sd1, texcoord - ddy);
		vec4 t2 = vec4(texcoord - sd2, texcoord + ddx);
		vec4 t3 = vec4(texcoord + sd1, texcoord + ddy);
		vec4 t4 = vec4(texcoord + sd2, texcoord - ddx);
		vec4 t5 = vec4(texcoord - dg1, texcoord - dg2);
		vec4 t6 = vec4(texcoord + dg1, texcoord + dg2);
				
		vec3 i1 = texture2D(texture, t1.xy).xyz;
		vec3 i2 = texture2D(texture, t2.xy).xyz;
		vec3 i3 = texture2D(texture, t3.xy).xyz;
		vec3 i4 = texture2D(texture, t4.xy).xyz;
		
		vec3 o1 = texture2D(texture, t5.xy).xyz;
		vec3 o3 = texture2D(texture, t6.xy).xyz;
		vec3 o2 = texture2D(texture, t5.zw).xyz;
		vec3 o4 = texture2D(texture, t6.zw).xyz;
		
		vec3 s1 = texture2D(texture, t1.zw).xyz;
		vec3 s2 = texture2D(texture, t2.zw).xyz;
		vec3 s3 = texture2D(texture, t3.zw).xyz;
		vec3 s4 = texture2D(texture, t4.zw).xyz;
	
	
		float ko1 = dot(abs(o1 - c), dt);
		float ko2 = dot(abs(o2 - c), dt);
		float ko3 = dot(abs(o3 - c), dt);
		float ko4 = dot(abs(o4 - c), dt);
		
		float k1 = min(dot(abs(i1 - i3), dt), max(ko1, ko3));
		float k2 = min(dot(abs(i2 - i4), dt), max(ko2, ko4));
		
		float w1 = k2; if (ko3 < ko1) w1 *= ko3 / ko1;
		float w2 = k1; if (ko4 < ko2) w2 *= ko4 / ko2;
		float w3 = k2; if (ko1 < ko3) w3 *= ko1 / ko3;
		float w4 = k1; if (ko2 < ko4) w4 *= ko2 / ko4;

	
		c = (w1 * o1 + w2 * o2 + w3 * o3 + w4 * o4 + 0.001 * c) / (w1 + w2 + w3 + w4 + 0.001);
		w1 = K * dot(abs(i1 - c) + abs(i3 - c), dt) / (0.125 * dot(i1 + i3, dt) + LUM_ADD);
		w2 = K * dot(abs(i2 - c) + abs(i4 - c), dt) / (0.125 * dot(i2 + i4, dt) + LUM_ADD);
		w3 = K * dot(abs(s1 - c) + abs(s3 - c), dt) / (0.125 * dot(s1 + s3, dt) + LUM_ADD);
		w4 = K * dot(abs(s2 - c) + abs(s4 - c), dt) / (0.125 * dot(s2 + s4, dt) + LUM_ADD);
		
		w1 = clamp(w1 + MX, MIN_W, MAX_W);
		w2 = clamp(w2 + MX, MIN_W, MAX_W);
		w3 = clamp(w3 + MX, MIN_W, MAX_W);
		w4 = clamp(w4 + MX, MIN_W, MAX_W);
	
		color = vec4((w1 * (i1 + i3) + w2 * (i2 + i4) + w3 * (s1 + s3) + w4 * (s2 + s4) + c) / (2.0 * (w1 + w2 + w3 + w4) + 1.0), texture2D(texture, texcoord).a) * glcolor * texture2D(lightmap, lmcoord);
	}

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
}
