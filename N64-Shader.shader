Shader "Retro Shaders/Nintendo 64"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)

        _Vibrance ("Vibrance", Float) = 1.0

        _Ambient ("Ambient", Float) = 0.28
        _LightBoost ("Light Boost", Float) = 2.26

        _CreaseStrength ("Crease Strength", Float) = 1.2

        _FogColor ("Fog Color", Color) = (0.7, 0.75, 0.8, 1)
        _FogStart ("Fog Start", Float) = 10
        _FogEnd ("Fog End", Float) = 80

        [Enum(Front,0,Back,1,Both,2)]
        _CullMode ("Render Side", Float) = 0

        [Enum(Smooth,0,Hard,1)]
        _ShadingMode ("Shading Mode", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalRenderPipeline"
        }

        Pass
        {
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float light : TEXCOORD2;
                float fog : TEXCOORD3;
                float crease : TEXCOORD4;
            };

            sampler2D _MainTex;

            float4 _Color;
            float4 _FogColor;

            float _Vibrance;
            float _Ambient;
            float _LightBoost;

            float _CreaseStrength;

            float _FogStart;
            float _FogEnd;

            float _ShadingMode;

            float computeCrease(float3 n)
            {
                float3 a = abs(n);
                float c = 1.0 - (a.x * a.y + a.y * a.z + a.z * a.x);
                return saturate(c) * _CreaseStrength;
            }

            v2f vert(appdata v)
            {
                v2f o;

                VertexPositionInputs posInput = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs nrmInput = GetVertexNormalInputs(v.normal);

                o.pos = posInput.positionCS;
                o.uv = v.uv;
                o.worldPos = posInput.positionWS;

                float3 n = normalize(nrmInput.normalWS);
                Light light = GetMainLight();

                float ndotl = saturate(dot(n, normalize(light.direction)));

                float lightVal = ndotl * _LightBoost;
                lightVal = max(lightVal, _Ambient);

                if (_ShadingMode > 0.5)
                    lightVal = floor(lightVal * 4.0) / 4.0;

                o.light = lightVal;

                o.crease = computeCrease(n);

                float depth = posInput.positionVS.z;
                o.fog = saturate((_FogEnd - depth) / (_FogEnd - _FogStart));

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv) * _Color;

                float light = i.light;
                light *= (1.0 - i.crease * 0.35);

                col.rgb *= light;

                float gray = dot(col.rgb, float3(0.299, 0.587, 0.114));
                col.rgb = lerp(gray.xxx, col.rgb, _Vibrance);

                col.rgb = lerp(_FogColor.rgb, col.rgb, i.fog);

                return col;
            }

            ENDHLSL
        }
    }

    Fallback Off
}