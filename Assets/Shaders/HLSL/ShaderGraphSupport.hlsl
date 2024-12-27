#ifndef SHADER_GRAPH_SUPPORT_H
#define SHADER_GRAPH_SUPPORT_H

struct Blade
{
    float3 position;
    float windOffset;
};

StructuredBuffer<Blade> _BladeBuffer;

// Use static variables to hold values
static float3 position;
static float windOffset;

inline void SetUpInstancedValues(uint instanceID, inout float4x4 objectToWorld, inout float4x4 worldToObject)
{
#if UNITY_ANY_INSTANCING_ENABLED

    Blade bladeGrass = _BladeBuffer[instanceID];
    
    position = bladeGrass.position;
    windOffset = bladeGrass.windOffset;

#endif
}

void GetInputInfo_float(in float3 In, out float3 Out, out float3 o_position, out float o_windOffset)
{
    Out = In;
    o_position = position;
    o_windOffset = windOffset;
}

void setup()
{
#if UNITY_ANY_INSTANCING_ENABLED
    SetUpInstancedValues(unity_InstanceID, unity_ObjectToWorld, unity_WorldToObject);
#endif
}

#endif