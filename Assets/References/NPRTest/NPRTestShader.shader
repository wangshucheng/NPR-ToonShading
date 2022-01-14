// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'defined _FACESHADOW_MAP' with 'defined (_FACESHADOW_MAP)'

Shader "Custom/NPRTest"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {} //主贴图
        _RampTex("Ramp Texture",2D) = "white"{}//Ramp贴图
        _MetalTex("Metal Texture",2D) = "white"{} //金属高光贴图
        _LightShadowMap("Shadow Texture",2D) = "white"{}//阴影纹理贴图

        _MainColor("Main Color",Color) = (1,1,1) //主色调
        _ShadowColor("Shadow Color",Color) = (0.7,0.7,0.8) //冷色调
        _ShadowRange("Shadow Range",Range(0,1)) = 0.5 //占比控制
        _ShadowSmooth("Shadow Smooth",Range(0,1)) = 0.2 //交接平滑度

        [Space(10)]
        _FaceShadowMap("Face ShadowMap",2D) = "white"{}//面部阴影贴图
        _FaceShadowMapPow("Face ShadowMap pow",Range(0.15,0.3)) = 0.15//阴影变化权重
        _FaceShadowOffset("Face ShadowOffset",Range(0,1)) = 0//面部阴影偏移，防止产生跳变
        [Toggle]_IgnoreLightY("WhetherFixLightY",float) = 0

        [Space(10)]
        _SpecularGloss("Specular Gloss",Range(0,128)) = 32
        _SpecularColor("Speuclar Color",Color) = (0.7,0.7,0.8)

        [Space(10)]
        _RimColor("Rim Color",Color) = (1,1,1,1) //边缘光
        _RimMax("Rim Max",Range(0,1)) = 0.5//控制字段
        _RimMin("Rim Min",Range(0,1)) = 0.5
        _RimSmooth("Rim Smooth",Range(0,1)) = 0.2 //边缘光平滑度

        [Space(10)]
        _OutLineWidth("Outline Width",Range(0,2)) = 0.24
        _OutLineColor("Outline Color",Color) = (0.5,0.5,0.5,1)
        _Factor("Outline Factor",Range(0,1)) = 0.5

        [Space(10)]
        _OffsetMul("_RimWidth",Range(0,0.1)) = 0.012
        _Threshold("_Threshold",Range(0,1)) = 0.09

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 100

            Pass
            {
                Tags {"LightMode" = "ForwardBase"}

                Cull Back

                CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #pragma target 3.5 

                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                #pragma shader_feature _FACESHADOW_MAP

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _RampTex;
                float4 _RampTex_ST;
                sampler2D _MetalTex;
                float4 _MetalTex_ST;
                sampler2D _FaceShadowMap;
                float4 _FaceShadowMap_ST;
                sampler2D _LightShadowMap;

                sampler2D _CameraDepthTexture;

                // UNITY_DECLARE_TEX2D(_FaceShadowMap);
                half _FaceShadowOffset;
                half _FaceShadowMapPow;
                float _IgnoreLightY;

                half3 _MainColor;
                half3 _ShadowColor;
                half4 _RimColor;

                half _RimMax;
                half _RimMin;
                half _RimSmooth;
                half _ShadowRange;
                half _ShadowSmooth;

                half _OffsetMul;
                half _Threshold;

                half _SpecularGloss;
                half4 _SpecularColor;

                struct a2v
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float4 vertexColor : Color;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float3 worldNormal : TEXCOORD1;
                    float3 worldPos : TEXCOORD2;
                    float3 positionVS : TEXCOORD3;
                };

                float4 TransformClipToViewPortPos(float4 positionCS)
                {
                    float4 o = positionCS * 0.5f;
                    o.xy = float2(o.x,o.y * _ProjectionParams.x) + o.w;
                    o.zw = positionCS.zw;
                    return o / o.w;
                }

                v2f vert(a2v v)
                {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.positionVS = UnityObjectToViewPos(v.vertex);
                    return o;
                }

                half4 frag(v2f i) : SV_TARGET
                {
                    half4 col = 1;
                    half4 mainTex = tex2D(_MainTex,i.uv);
                    half4 metalTex = tex2D(_MetalTex,i.uv);
                    half4 LightMapShadow = tex2D(_LightShadowMap,i.uv);

                    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                    half3 worldNormal = normalize(i.worldNormal);
                    half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    half halfLambert = dot(worldNormal,worldLightDir) * 0.5 + 0.5;

                    //漫反射计算部分
                    // float3 ramp = tex2D(_RampTex, float2(halfLambert, halfLambert)).rgb;//上面这样采样会出现不正常的高光区域
                    float3 ramp = tex2D(_RampTex,float2(saturate(halfLambert - _ShadowRange),0.5));
                    float3 rampStart = tex2D(_RampTex, float2(0,0)).rgb;
                    half rampNum = smoothstep(0,_ShadowSmooth,halfLambert - _ShadowRange);
                    half3 RampColor = lerp(rampStart,ramp,rampNum);

                    //阴影层级计算
                    //如果SFactor = 0，ShallowShadowColor为一级阴影色，否则为BaseColor
                    float SWeight = (LightMapShadow.g * RampColor.r + halfLambert) * 0.5 + 1.125;
                    float SFactor = floor(SWeight - _ShadowRange);
                    half3 ShallowShadowColor = SFactor * _MainColor.rgb + (1 - SFactor) * _ShadowColor.rgb;
                    half rampS = smoothstep(0,_ShadowSmooth,halfLambert - _ShadowRange);
                    ShallowShadowColor = lerp(_ShadowColor,_MainColor,rampS);

                    half3 diffuse = RampColor;
                    diffuse *= LightMapShadow.a == 0 ? 1 : ShallowShadowColor;
                    diffuse *= mainTex.a == 0 ? 1 : mainTex.rgb;//用三目运算符替代IF执行裁剪操作
                    // half ramp = smoothstep(0,_ShadowSmooth,halfLambert - _ShadowRange);
                    // half3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor;//在这里抉择冷色调还是暖色调

                    //高光计算部分
                    half3 halfDir = normalize(worldLightDir + viewDir);
                    fixed3 specularColor = _SpecularColor.rgb * pow(max(0,dot(worldNormal,halfDir)),_SpecularGloss);
                    fixed3 specular = metalTex.a == 0 ? 0 : specularColor * metalTex.rgb;

                    // 边缘光计算(视向量做法)
                    // half f = 1.0 - saturate(dot(viewDir,worldNormal));
                    // half rim = smoothstep(_RimMin,_RimMax,f);
                    // rim = smoothstep(0,_RimSmooth,rim);
                    // half3 rimColor = rim * _RimColor.rgb * _RimColor.a;

                    //边缘光计算部分(屏幕空间深度边缘光)
                    float3 normalWS = i.worldNormal;
                    float3 normalVS = UnityWorldToViewPos(normalWS);
                    float3 positionVS = i.positionVS;
                    float3 samplePositionVS = float3(positionVS.xy + normalVS.xy * _OffsetMul,positionVS.z);
                    float4 samplePositionCS = UnityViewToClipPos(samplePositionVS);
                    float4 samplePositionVP = TransformClipToViewPortPos(samplePositionCS);

                    float depth = i.pos.z / i.pos.w;
                    float linearEyeDepth = LinearEyeDepth(depth);
                    float offsetDepth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture,samplePositionVP));
                    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth);
                    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
                    float rimIntensity = step(_Threshold,depthDiff);
                    half3 rimColor = rimIntensity * _RimColor.rgb * _RimColor.a;

                    #if defined (_FACESHADOW_MAP) //面部阴影修正
                        float lightDataLeft = tex2D(_FaceShadowMap,i.uv);
                        float lightDataRight = tex2D(_FaceShadowMap,float2(1 - i.uv.x,i.uv.y));
                        float2 lightData = float2(lightDataRight,lightDataLeft);
                        float3 Fronts = float3(0,0,1);
                        float3 Right = float3(1,0,0);

                        float sinx = sin(_FaceShadowOffset);
                        float cosx = cos(_FaceShadowOffset);
                        float2x2 rotationOffset = float2x2(cosx,-sinx,sinx,cosx);
                        float2 lightDir = mul(rotationOffset,worldLightDir.xz);
                        lightData = pow(abs(lightData), _FaceShadowMapPow);

                        float FrontL = dot(normalize(Fronts.xz), normalize(lightDir));
                        float RightL = dot(normalize(Right.xz), normalize(lightDir));
                        RightL = -(acos(RightL) / 3.14159265 - 0.5) * 2;
                        float lightAttenuation = (FrontL > 0) * min(
                            (lightData.r > RightL),
                            (lightData.g > -RightL)
                        );


                        half3 FaceColor = lerp(mainTex.rgb * rampStart.rgb * _ShadowColor.rgb,  mainTex.rgb * ramp.rgb * _SpecularColor, lightAttenuation);
                        col.rgb = FaceColor;
                    #else //非面部阴影的计算区域
                        col.rgb = (diffuse + specular + rimColor) * _LightColor0.rgb;
                        col.a = mainTex.a;
                    #endif
                        // half4 test = half4(0,rampTex.g,0,255);
                        return col;

                    }


                    ENDCG
                }

                Pass
                {
                    Tags {"LightMode" = "ForwardBase"}

                    //开启正向剔除
                    Cull Front

                    CGPROGRAM

                    #pragma vertex vert
                    #pragma fragment frag

                    #include "UnityCG.cginc"

                    sampler2D _MainTex;
                    float4 _MainTex_ST;//尝试用贴图采样轮廓线颜色

                    half _OutLineWidth;
                    half4 _OutLineColor;
                    float _Factor;

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
                        float2 uv : TEXCOORD0;
                        float3 vertColor : TEXCOORD1;
                    };

                    v2f vert(a2v v)
                    {
                        v2f o;
                        float3 pos = normalize(v.vertex.xyz);
                        // float3 normal = normalize(v.normal);
                        float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);

                        //点积是为了确定顶点对于几何中心的指向，判断此处的顶点是位于模型的凹处还是凸处
                        float D = dot(pos,normal);
                        //矫正顶点的方向值，判定是否是轮廓线
                        pos *= sign(D);
                        //描边的朝向插值，决定是偏向法线方向还是顶点方向
                        pos = lerp(normal,pos,_Factor);
                        //将顶点往指定方向挤出
                        v.vertex.xyz += pos * _OutLineWidth;

                        o.pos = UnityObjectToClipPos(v.vertex);
                        o.vertColor = v.vertColor.rgb;//如果有顶点色才使用
                        o.uv = TRANSFORM_TEX(v.uv,_MainTex);

                        return o;

                    }

                    fixed4 frag(v2f i) : SV_TARGET
                    {
                        i.vertColor = tex2D(_MainTex,i.uv).rgb;
                        return fixed4(_OutLineColor * i.vertColor,0);
                    }

                    ENDCG
                }

                Pass
                {
                    Tags {"LightMode" = "ShadowCaster"}

                    CGPROGRAM

                    #pragma target 3.0

                    #pragma vertex Shadowvert
                    #pragma fragment ShadowFrag

                    #include "UnityCG.cginc"

                    struct VertexData {
                        float4 position : POSITION;
                    };

                    float4 Shadowvert(VertexData v) : SV_POSITION{
                        return UnityObjectToClipPos(v.position);
                    }

                    half4 ShadowFrag() : SV_TARGET{
                        return 0;
                    }

                    ENDCG

                }
        }

            CustomEditor "NPRShaderGUI"
}