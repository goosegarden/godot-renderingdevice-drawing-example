
#version 450

layout(location = 0) in vec3 nor;
layout(location = 1) in vec3 fragpos;
layout(location = 2) in vec2 uv;
layout(location = 3) in vec3 ligth_pos;
layout(location = 4) in vec3 light_col;
layout(location = 5) in float light_int;


layout( set = 0, binding = 1 ) uniform  sampler2D atex0;

layout(location=0) out vec4 fragColor;


void main() {
	
	vec3 norm = normalize(nor);

	vec3 lightDir = normalize(ligth_pos - fragpos);  

	float diff = max(dot(norm, lightDir), 0.0);

	vec4 col1 = texture(atex0,vec2(uv.x, -uv.y));

	vec3 diffuse = diff * col1.rgb  + vec3(0.0,0.0,0.1);
	fragColor=vec4(diffuse,1.0);


}
