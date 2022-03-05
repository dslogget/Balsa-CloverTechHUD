Shader "Unlit/MyShaderRotation.shader"
{
    Properties
    {
        _CentreClampTex ("Texture", 2D) = "" {}
        _PitchClampTex ("Texture", 2D) = "" {}
        _RollClampTex ("Texture", 2D) = "" {}
        _YawClampTex ("Texture", 2D) = "" {}
        _Colour ("Colour", COLOR) = (0,1,0,1)
        _AlphaClip ("Alpha Clip", Range(0,1)) = 1.0
        _Pitch ( "Pitch", Float ) = 0
        _Roll ( "Roll", Float ) = 0
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
                float4 pitchRollYawUp : TEXCOORD1;
                float cosV : TEXCOORD2;
            };

            Texture2D _CentreClampTex;
            float4 _CentreClampTex_ST;
            Texture2D _PitchClampTex;
            float4 _PitchClampTex_ST;
            Texture2D _RollClampTex;
            float4 _RollClampTex_ST;
            Texture2D _YawClampTex;
            float4 _YawClampTex_ST;
            fixed4 _Colour;
            float1 _MySize;
            float1 _AlphaClip;
            float1 _Pitch;
            float1 _Roll;


            SamplerState smpClampPoint;
            SamplerState smp_ClampU_MirrorV_Point;


            static const float PI = 3.14159265f;


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

                float3 Up = normalize(mul((float3x3)unity_ObjectToWorld, float3(0,1,0)));
                float3 Front = normalize(mul((float3x3)unity_ObjectToWorld, float3(1,0,0)));


                float pitch = -atan2(Front.y, sign(Up.y) * length(Front.xz));

                if (abs(pitch) >= PI/2) {
                    pitch = PI - pitch;
                }

                float3 Right = normalize(mul((float3x3)unity_ObjectToWorld, float3(0, 0, 1)));

                // Form a plane with Front as one axis
                // float3 PitchRotPlaneNorm = normalize(cross(Front, float3(Front.x, 0, Front.z)));
                float3 PitchRotPlaneNorm = normalize(cross(Front, float3(0, 1, 0)));
                float3 SupportAxis = cross(Front, PitchRotPlaneNorm);
                float3 transformedRight = float3(dot(Front, Right),
                                                 dot(PitchRotPlaneNorm, Right),
                                                 dot(SupportAxis, Right));

                float roll = atan2(sign(dot(Up,PitchRotPlaneNorm))*length(transformedRight.xz), transformedRight.y);

                o.pitchRollYawUp = float4(pitch,
                                          roll,
                                          atan2(Front.x,Front.z),
                                          sign(Up.y));

                o.cosV = dot(Front,
                             normalize(mul(unity_CameraToWorld,float3(0,0,-1))));

                return o;
            }

            float2 rotate( float2 toRotate, float angle ) {
                return float2( toRotate.x * cos( angle ) - toRotate.y * sin( angle ),
                               toRotate.x * sin( angle ) + toRotate.y * cos( angle ) );
            }

            float2 rotateAboutPoint( float2 toRotate, float2 pt, float angle ) {
               return pt + rotate( toRotate - pt, angle );
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 originalTangNorm = normalize(i.tangSpaceViewDir.xyz);
                i.tangSpaceViewDir.xy = i.tangSpaceViewDir.xy / abs(i.tangSpaceViewDir.z);
                float2 uv = TRANSFORM_TEX(float2(i.tangSpaceViewDir.y, i.tangSpaceViewDir.x),
                                          _CentreClampTex );


                i.tangSpaceViewDir.xy = rotate(i.tangSpaceViewDir.xy,
                                               i.pitchRollYawUp.y);
                i.tangSpaceViewDir.x = i.tangSpaceViewDir.x
                                       + 2 * i.pitchRollYawUp.x / PI;

                fixed4 col = _Colour;
                float flip;
                if (abs(i.tangSpaceViewDir.x) > 1 && abs(i.tangSpaceViewDir.x) < 3) {
                    flip = -1;
                }
                else
                {
                    flip = 1;
                }

                float2 pitchuv = TRANSFORM_TEX(float2(flip * i.tangSpaceViewDir.y, i.tangSpaceViewDir.x ),
                                               _PitchClampTex );

                fixed4 sample = _CentreClampTex.Sample(smpClampPoint, float2(uv / 2 + 0.5) ) +
                                _PitchClampTex.Sample(smp_ClampU_MirrorV_Point, float2(pitchuv / 2 + 0.5 ) );
                
                clip(sample.a < _AlphaClip ? -1 : 1);

                // To limit how much can be seen when far away
                col.a =  (1 - smoothstep( 10, 15, length(i.tangSpaceViewDir) ))
                         *(1- smoothstep(0.4, 0.6, abs(originalTangNorm.x)))
                         *(1- smoothstep(0.4, 0.6, abs(originalTangNorm.y)))
                         *(1- smoothstep(15*PI/180, 35.0*PI/180, abs(acos(i.cosV))));
                clip(col.a);
                return col;
            }
            ENDCG
        }
    }
}
