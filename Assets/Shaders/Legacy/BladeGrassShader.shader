Shader"Unlit/BladeGrassShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _MeshDeformationLimitLow ("Mesh Deformation low limit", Range(0.0, 5.0)) = 0.08
        _MeshDeformationLimitTop ("Mesh Deformation top limit", Range(0.0, 5.0)) = 2.0
        _WindNoiseScale ("Wind Noise Scale", float) = 2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct bladegrass
            {
                float3 position;
                float windOffset;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 view_dir : TEXCOORD3;
                float3 pos_world : TEXCOORD4;
                float fresnel : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Properties
            float _Height;
            float _Offset;
            float _ShadingOffset;
            float _ShadingParameter;

            float _SideOffsetAmount;
            float4 _WindDirection;
            float _WindSpeed;
            float _NoiseOffset;
            float _MeshDeformationLimitLow;
            float _MeshDeformationLimitTop;
            float _WindNoiseScale;


            // Compute shader
            StructuredBuffer<bladegrass> _BladeBuffer;

            float rand(float2 co) {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            float4x4 rotateY(float angle) {
                float c = cos(angle);
                float s = sin(angle);
                return float4x4(
                    c, 0, s, 0,
                    0, 1, 0, 0,
                    -s, 0, c, 0,
                    0, 0, 0, 1
                );
            }

            // A quadratic bezier curve function
            float3 quadraticBezierCurve(float3 p0, float3 p1, float3 p2, float t)
            {
                float a = (1 - t) * (1 - t);
                float b = 2 * (1 - t) * t;
                float c = t * t;

                float x = a * p0.x + b * p1.x + c * p2.x;
                float y = a * p0.y + b * p1.y + c * p2.y;
                float z = a * p0.z + b * p1.z + c * p2.z;

                return float3(x, y, z);
            }

            float3 calculateBezierCurveTangent(float3 p0, float3 p1, float3 p2, float t)
            {
                return 2 * (1 - t) * (p1 - p0) + 2 * t * (p2 - p1);
            }

            // Simple Noise Node
            // https://docs.unity3d.com/Packages/com.unity.shadergraph@7.1/manual/Simple-Noise-Node.html
            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                Out = t;
            }

            v2f vert (appdata v, uint instanceID : SV_InstanceID)
            {

                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                bladegrass blade = _BladeBuffer[instanceID];
                v.vertex.xyz *= float3(10.0, 10.0, 10.0);
                float3 spawnPos = blade.position;

                // Use Bezier curve to deform the shape
                float3 up_vector = float3(0.0, 0.0, 1.0);
                float3 p0 = float3(0.0, 0.0, 0.0);                  // One endpoint
                float3 p2 = float3(sqrt(_Offset), sqrt(_Height), 0.0);

                float project_length = length(p2 - p0 - up_vector * dot(p2 - p0, up_vector));
                float3 p1 = p0 + _Height * up_vector * max(1 - project_length / _Height, 0.05 * max(project_length / _Height, 1.0));

                float3 knotPoint = quadraticBezierCurve(p0, p1, p2, v.uv.y);
                float3 tangent = normalize(calculateBezierCurveTangent(p0, p1, p2, v.uv.y));
                
                // Apply knot point to vertex
                v.vertex += float4(knotPoint, 1.0);

                // Rotate along y-axis with a random degree
                float randomAngle = rand(spawnPos.xz) * 360.0;
                float4x4 rotateMatrix = rotateY(randomAngle);
                v.vertex = mul(rotateMatrix, v.vertex); 
                // Apply rotation matrix to normal
                v.normal = mul(rotateMatrix, float4(v.normal, 0.0));

                // Apply vertex to world position
                float3 worldVertPos = spawnPos + mul(unity_ObjectToWorld, v.vertex).xyz;

                // Use world uv to sample noise from win texture
                float2 world_uv = worldVertPos.xz + _WindDirection * _Time.y;
                float local_noise = 0.0;
                Unity_SimpleNoise_float(world_uv, _WindNoiseScale, local_noise);
                local_noise += _NoiseOffset;

                // Keep bottom part of mesh at its position
                float smoothedDeformation = smoothstep(_MeshDeformationLimitLow, _MeshDeformationLimitTop, v.uv.y);
                float distortion = smoothedDeformation * local_noise;

                // Apply distortion
                worldVertPos.xz += distortion * _WindSpeed * normalize(_WindDirection);
                float3 objectVertPos = mul(unity_WorldToObject, float4(worldVertPos, 1.0)).xyz;

				o.uv = v.uv;
                o.normal = v.normal;
				o.vertex = UnityObjectToClipPos(objectVertPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float shading = saturate(dot(_WorldSpaceLightPos0.xyz, i.normal));
				shading = (shading + _ShadingOffset) / _ShadingParameter;
                
                // Diffuse color
                float3 grass_color_bottom = float3(0.05, 0.2, 0.01);
                float3 grass_color_tip = float3(0.50, 0.50, 0.10);
                float3 diffuse_color = lerp(grass_color_bottom, grass_color_tip, i.uv.y);

                return float4(diffuse_color * shading, 1.0);
            }
            ENDCG
        }
    }
}
