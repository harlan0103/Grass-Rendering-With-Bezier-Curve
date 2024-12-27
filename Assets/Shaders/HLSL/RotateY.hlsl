void rotateY_float(float angle, out float4x4 rotateMatrix) {
    float c = cos(angle);
    float s = sin(angle);
    rotateMatrix = float4x4(
        c, 0, s, 0,
        0, 1, 0, 0,
        -s, 0, c, 0,
        0, 0, 0, 1
    );
}