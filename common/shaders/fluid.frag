in vec2 uv;
out vec4 FragCd;

uniform sampler2D collisionSampler;
uniform sampler2D velSampler;
uniform sampler2D densitySampler;

void main()
{
    vec4 collTexture = texture(collisionSampler, uv);
    vec4 densityTexture = texture(densitySampler, uv);
    vec4 velTexture = texture(velSampler, uv);

    vec2 vel = velTexture.xy;
    float density = densityTexture.r;
    float collision = max(collTexture.r, 0);

    if (collision <= 0)
    {
        FragCd = vec4(0, 0.5, 0.5, 1.0);
        return;
    }

    FragCd = vec4(
        vec3(
            sqrt(min(density, 1))
        ), 
        1.0
    );
    //FragCd = vec4(vec3(-densityTexture.g), 1.0);
    //FragCd = vec4(vec3(vel.x*vel.x+vel.y*vel.y)*0.2, 1.0);
    //FragCd = vec4(mix(vec3(0, 1, 0), vec3(0, 0, 0), collision), 1.0);
    //FragCd = vec4(collision, 0, 0, 1);
    //FragCd = vec4(vel*0.25, 0.0, 1.0);
}