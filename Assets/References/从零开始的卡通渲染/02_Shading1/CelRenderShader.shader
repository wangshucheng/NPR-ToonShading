Shader "Unlit/CelRender"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1,1,1)
    _ShadowColor("Shadow Color", Color) = (0.7, 0.7, 0.8)
    _ShadowRange("Shadow Range", Range(0, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.2

        [Space(10)]
    _OutlineWidth("Outline Width", Range(0.01, 2)) = 0.24
        _OutLineColor("OutLine Color", Color) = (0.5,0.5,0.5,1)
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        pass
        {
           Tags {"LightMode" = "ForwardBase"}

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
        float4 _MainTex_ST;
            half3 _MainColor;
        half3 _ShadowColor;
        half _ShadowRange;
        half _ShadowSmooth;

            struct a2v
       {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
       {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
        float3 worldPos : TEXCOORD2;
            };


            v2f vert(a2v v)
      {
                v2f o;
        UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
       {
                half4 col = 1;
                half4 mainTex = tex2D(_MainTex, i.uv);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
        half3 worldNormal = normalize(i.worldNormal);
                half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
        half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                // cel漫反射
                //half3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor;
                
                // smoothstep柔化明暗边界
                half ramp = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowRange);
                half3 diffuse = lerp(_ShadowColor, _MainColor, ramp);

                // Ramp贴图
                //half ramp = tex2D(_rampTex, float2(saturate(halfLambert - _ShadowRange), 0.5)).r;
                //half3 diffuse = lerp(_ShadowColor, _MainColor, ramp);

                diffuse *= mainTex;
                col.rgb = _LightColor0 * diffuse;
                return col;
            }
            ENDCG
        }

Pass
    {
        Tags {"LightMode" = "ForwardBase"}

            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            half _OutlineWidth;
            half4 _OutLineColor;

            struct a2v
        {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 vertColor : COLOR;
                float4 tangent : TANGENT;
            };

            struct v2f
       {
                float4 pos : SV_POSITION;
                float3 vertColor : COLOR;
            };


            v2f vert(a2v v)
       {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
                ndcNormal.x *= aspect;
                pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                o.pos = pos;
                return o;

            }

            half4 frag(v2f i) : SV_TARGET
        {
                return fixed4(_OutLineColor * i.vertColor, 0);//顶点色rgb通道控制描边颜色
            }
            ENDCG
        }
    }
}