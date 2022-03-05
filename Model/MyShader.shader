Shader "Unlit/MyShader.shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Colour ("Colour", COLOR) = (0,1,0,1)
        _MySize ("Size", Float) = 1.0
        _AngleBias ("Angle bias X", Float) = 0.0
        _AxisBias ("Axis of bias ", Vector) = (0,0,0,0)
        _AlphaClip ("Alpha Clip", Float) = 1.0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull front
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
               float4 vertex   : POSITION;
               float2 uv       : TEXCOORD0;
               float3 normal   : NORMAL;
               float4 tangent  : TANGENT;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 pos : TEXCOORD0;
            };

            sampler2D _MainTex;
            fixed4 _Colour;
            float1 _MySize;
            float1 _AlphaClip;
            float4 _MainTex_ST;
            float1 _AngleBias;
            float4 _AxisBias;

            float3x3 AngleAxis3x3(float1 angle, float3 axis)
            {
                float1 c, s;
                sincos(angle, s, c);

                float1 t = 1 - c;
                float1 x = axis.x;
                float1 y = axis.y;
                float1 z = axis.z;

                return float3x3(
                    t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
                );
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal = v.normal;
                o.pos = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 biasedNorm = mul(AngleAxis3x3(_AngleBias, _AxisBias), i.normal);
                float3 worldNorm = UnityObjectToWorldNormal(biasedNorm);
                float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);

                float3 viewPos = UnityObjectToViewPos(i.pos);
                float3 viewDir = normalize(viewPos);
                float3 viewCross = cross(viewDir, viewNorm);

                viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
                float2 uv = viewNorm.xy;

                uv = _MySize * uv + 0.5f, 0, 1.0f;
                uv = TRANSFORM_TEX(uv, _MainTex);
                fixed4 col = _Colour;
                col[3] = tex2D(_MainTex, uv)[3];
                clip( col[3] < _AlphaClip ? -1:1 );
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //fixed4 col2 = { uv, 0, 1 };
                return col;
            }
            ENDCG
        }
    }
}
