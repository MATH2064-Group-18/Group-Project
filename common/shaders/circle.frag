in vec2 uv;
out vec4 FragCd;


void main()
{
    if (length(uv - vec2(0.5)) > 0.5)
    {
        discard;
    }
    
    FragCd = vec4(0.1, 0.5, 0.8, 1.0);
}