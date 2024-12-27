void rand_float(float2 co, out float randomSeed) 
{
    randomSeed = frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

void edgeRandom_float(float input, float offset, out float random)
{
    float weight = input - abs(input - 0.5f) * 2.0f;
    float sign = (input > 0.5f) ? -1.0f : 1.0f;
    
    float randomValue = frac(sin(input * 12.9898) * 43758.5453);

    random = offset * weight * sign * randomValue;
}