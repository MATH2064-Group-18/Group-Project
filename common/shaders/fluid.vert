layout (location = 0) in vec2 vPos;
layout (location = 1) in vec2 texUV;

out vec2 uv;

uniform vec2 viewScale;

void main()
{
    gl_Position = vec4(viewScale * vPos, 0.0, 1.0);
    uv = texUV;
}