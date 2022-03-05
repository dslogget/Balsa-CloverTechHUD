Shader "Unlit/MyShaderRotation.shader"
{
    Properties
    {
        _CentreClampTex ("Texture", 2D) = "" {}
        _PitchClampTex ("Texture", 2D) = "" {}
        _RollClampTex ("Texture", 2D) = "" {}
        _YawClampTex ("Texture", 2D) = "" {}
        _Colour ("Colour", COLOR) = (0,1,0,1)
        _AlphaClip ("Alpha Clip", Float) = 1.0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
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
                float3 tangSpaceViewDir : TEXCOORD0;
                float3 pitchYawRoll : TEXCOORD1;
            };

            sampler2D _CentreClampTex;
            float4 _CentreClampTex_ST;
            sampler2D _PitchClampTex;
            float4 _PitchClampTex_ST;
            sampler2D _RollClampTex;
            float4 _RollClampTex_ST;
            sampler2D _YawClampTex;
            float4 _YawClampTex_ST;
            fixed4 _Colour;
            float1 _MySize;
            float1 _AlphaClip;
            float1 _CentreSizeX;
            float1 _CentreSizeY;
            float1 _PitchSizeX;
            float1 _PitchSizeY;
            float1 _YawSizeX;
            float1 _YawSizeY;
            float1 _RollSizeX;
            float1 _RollSizeY;

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
                float1 tangentDir = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = tangentDir * cross( v.tangent, v.normal );

                float3 objSpaceViewDir = -ObjSpaceViewDir(v.vertex);
                o.tangSpaceViewDir = float3( dot(objSpaceViewDir, float3(0,1,0)),
                                                  dot(objSpaceViewDir, float3(0,0,1)),
                                                  dot(objSpaceViewDir, float3(-1,0,0)) );

                float3 worldUpObjectSpace = normalize(mul( unity_WorldToObject, float3(0,1,0) ));
                float3 worldForwardObjectSpace = normalize(mul( unity_WorldToObject, float3(1,0,0) ));
                o.pitchYawRoll = float3( atan2(-worldUpObjectSpace.x, worldUpObjectSpace.y),
                                         atan2(-worldUpObjectSpace.z, worldUpObjectSpace.y),
                                         atan2(-worldForwardObjectSpace.z, worldForwardObjectSpace.x) );

                // o.tangSpaceViewDir = float3( dot(objSpaceViewDir, v.tangent),
                //                                   dot(objSpaceViewDir, bitangent),
                //                                   dot(objSpaceViewDir, v.normal) );
                return o;
            }

            float2 rotate( float2 toRotate, float angle ) {
                return float2( toRotate.x * cos( angle ) - toRotate.y * sin( angle ),
                               toRotate.x * sin( angle ) + toRotate.y * cos( angle ) );
            }

            float2 rotateAboutPoint( float2 toRotate, float2 pt, float angle ) {
               return pt + rotate( toRotate - pt, angle );
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 originalTangNorm = normalize(i.tangSpaceViewDir.xyz);
                i.tangSpaceViewDir.xy = i.tangSpaceViewDir.xy / abs(i.tangSpaceViewDir.z);
                float2 uv = TRANSFORM_TEX(
                    float2( i.tangSpaceViewDir.y,
                            i.tangSpaceViewDir.x),
                    _CentreClampTex );

                // Bring down then rotate
                i.tangSpaceViewDir.x = i.tangSpaceViewDir.x + 2 * i.pitchYawRoll.x / 3.141592;
                i.tangSpaceViewDir.xy = rotateAboutPoint( i.tangSpaceViewDir.xy, 
                                                          float2(2 * i.pitchYawRoll.x / 3.141592, 0),
                                                          i.pitchYawRoll.y );

                float2 pitchuv = TRANSFORM_TEX(
                    float2( i.tangSpaceViewDir.y,
                            i.tangSpaceViewDir.x ),
                    _PitchClampTex );

                fixed4 sample = tex2D( _CentreClampTex, float2(uv / 2 + 0.5) ) +
                                tex2D( _PitchClampTex, float2(pitchuv / 2 + 0.5 ) );
                clip(sample.a < _AlphaClip ? -1 : 1);
                fixed4 col = _Colour;
              //col.a = clamp(  - smoothstep(10, 15, length(i.tangSpaceViewDir))
              //                + smoothstep(0.98, 0.983, abs(normalize( i.tangSpaceViewDir ).z)),
              //                -1, 1 );
                //float3 cosV = dot(normalize(unity_CameraToWorld._m12_m02_m22),originalTangNorm);
                col.a =  (1 - smoothstep( 10, 15, length(i.tangSpaceViewDir) ))
                         *(1- smoothstep(0.4, 0.6, abs(originalTangNorm.x)))
                         *(1- smoothstep(0.4, 0.6, abs(originalTangNorm.y)));
                //         *(1- smoothstep(10*3.141/180, 40.0*3.141/180, abs(acos(cosV))));
                clip(col.a);
                return col;//fixed4( uv, 0, 1 );
            }
            ENDCG
        }
    }
}
