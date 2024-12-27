// A quadratic bezier curve function
inline float3 quadraticBezierCurve(float3 p0, float3 p1, float3 p2, float t)
{
    float a = (1 - t) * (1 - t);
    float b = 2 * (1 - t) * t;
    float c = t * t;

    float x = a * p0.x + b * p1.x + c * p2.x;
    float y = a * p0.y + b * p1.y + c * p2.y;
    float z = a * p0.z + b * p1.z + c * p2.z;

    return float3(x, y, z);
}

inline float3 calculateBezierCurveTangent(float3 p0, float3 p1, float3 p2, float t)
{
    return 2 * (1 - t) * (p1 - p0) + 2 * t * (p2 - p1);
}

void CalculateKnotPoint_float(float scale_y, float curveOffset, float uv_y, out float3 knotPoint)
{
    // Use Bezier curve to deform the shape
    float height = scale_y + 0.001f;
    float3 up_vector = float3(0.0, 0.0, 1.0);
    float3 p0 = float3(0.0, 0.0, 0.0);                  // First control point
    float3 p2 = float3(0.0, sqrt(height), sqrt(curveOffset));

    float project_length = length(p2 - p0 - up_vector * dot(p2 - p0, up_vector));
    float3 p1 = p0 + height * up_vector * max(1 - project_length / height, 0.05 * max(project_length / height, 1.0));

    knotPoint = quadraticBezierCurve(p0, p1, p2, uv_y);
    //float3 tangent = normalize(calculateBezierCurveTangent(p0, p1, p2, uv_y));
}