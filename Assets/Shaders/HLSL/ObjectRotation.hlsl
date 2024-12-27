float3x3 QuaternionToMatrix(float4 q)
{
    float x = q.x, y = q.y, z = q.z, w = q.w;

    float3x3 rotationMatrix;
    rotationMatrix[0][0] = 1 - 2 * (y * y + z * z);
    rotationMatrix[0][1] = 2 * (x * y - z * w);
    rotationMatrix[0][2] = 2 * (x * z + y * w);

    rotationMatrix[1][0] = 2 * (x * y + z * w);
    rotationMatrix[1][1] = 1 - 2 * (x * x + z * z);
    rotationMatrix[1][2] = 2 * (y * z - x * w);

    rotationMatrix[2][0] = 2 * (x * z - y * w);
    rotationMatrix[2][1] = 2 * (y * z + x * w);
    rotationMatrix[2][2] = 1 - 2 * (x * x + y * y);

    return rotationMatrix;
}

void GetRotatedPosition_float(float4 quaternion, float3 position, out float3 rotatedPos)
{
    float3x3 rotationMatrix = QuaternionToMatrix(quaternion);
    
    rotatedPos = mul(rotationMatrix, position);
}
