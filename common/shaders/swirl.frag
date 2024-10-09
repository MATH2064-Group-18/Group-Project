in vec2 uv;
out vec4 FragCd;

uniform sampler2D collisionSampler;
uniform sampler2D velSampler;
uniform sampler2D densitySampler;
uniform sampler2D restposSampler;

void main()
{
    vec4 collTexture = texture(collisionSampler, uv);
    vec4 densityTexture = texture(densitySampler, uv);
    vec4 velTexture = texture(velSampler, uv);
    vec4 restposTexture = texture(restposSampler, uv);

    vec2 vel = velTexture.xy;
    float density = densityTexture.r;
    float collision = max(collTexture.r, 0);

    vec2 rest = restposTexture.xy;

    float d = tanh(4 * density);

    if (collision <= 0)
    {
        FragCd = vec4(0, 0.5, 0.5, 1.0);
        return;
    }

    FragCd = vec4(
        pow(1.02*vec3(rest.x,
        0.1 * (1 - rest.x) * (1 - rest.y),
        rest.y), vec3(2.2)),
        1.0
    );
}