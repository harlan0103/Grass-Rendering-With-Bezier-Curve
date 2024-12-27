Shader "Unlit/MipmapCalculationShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            ZWrite Off
            ZTest Always
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float calculateMipmapDepth(float2 uv)
            {
                float4 depth;
                float offset = _MainTex_TexelSize.x / 2;
                depth.x = tex2D(_MainTex, uv);
                depth.y = tex2D(_MainTex, uv + float2(0, offset));
                depth.z = tex2D(_MainTex, uv + float2(offset, 0));
                depth.w = tex2D(_MainTex, uv + float2(offset, offset));

                return min(min(depth.x, depth.y), min(depth.z, depth.w));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = calculateMipmapDepth(i.uv);
                return float4(depth, 0, 0, 1.0f);
            }
            ENDCG
        }
    }
}
