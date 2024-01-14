
#version 450

layout(location=0) in vec3 vertex_pos;
layout(location=1) in vec3 norm;
layout(location=2) in vec2 in_uv;

layout( std140, set = 0, binding = 0 ) uniform mat
	{
	mat4 uModelMatrix;
	mat4 uViewMatrix;
	mat4 uProjectionMatrix;
} Matrices;

layout( set = 0, binding = 1 ) uniform  sampler2D atex0;
layout( set = 0, binding = 2 ) uniform light
	{
		vec3 position;
		vec3 color;
		float intensity;
}lights;




layout(location = 0) out vec3 nor;
layout(location = 1) out vec3 fragpos;
layout(location = 2) out vec2 out_uv;
layout(location = 3) out vec3 light_pos;
layout(location = 4) out vec3 light_col;
layout(location = 5) out float light_int;



void main() {

	out_uv = in_uv;

	light_pos = lights.position;
	light_col = lights.color;
	light_int = lights.intensity;

	nor = mat3(transpose(inverse(Matrices.uModelMatrix))) * norm;
	fragpos = (Matrices.uModelMatrix * vec4(vertex_pos.xyz,1.0)).xyz;
	gl_Position=  Matrices.uProjectionMatrix  *  Matrices.uViewMatrix *  Matrices.uModelMatrix * vec4(vertex_pos.xyz,1.0);
	
}
