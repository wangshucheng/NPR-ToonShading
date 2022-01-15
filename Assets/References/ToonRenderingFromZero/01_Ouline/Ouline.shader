Shader "Unlit/Ouline"
{
    Properties
    {
    _OutlineWidth("Outline Width", Range(0.01, 1)) = 0.24
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

            float4 vert(appdata_base v) : SV_POSITION
        {
                return UnityObjectToClipPos(v.vertex);
            }

            half4 frag() : SV_TARGET
       {
                return half4(1,1,1,1);
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
                // ���
        //        v2f o;
        //UNITY_INITIALIZE_OUTPUT(v2f, o);
        //        o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * _OutlineWidth * 0.1 ,1));//�������ŷ��߷�������
        //        return o;

                // ��������������������
                //v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                //float4 pos = UnityObjectToClipPos(v.vertex);
                //float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//�����߱任��NDC�ռ�
                //pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                //o.pos = pos;
                //return o;

                // ���ݴ��ڵĿ�߱��ٽ�������
                //v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                //float4 pos = UnityObjectToClipPos(v.vertex);
                //float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//�����߱任��NDC�ռ�
                //float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//�����ü������Ͻ�λ�õĶ���任���۲�ռ�
                //float aspect = abs(nearUpperRight.y / nearUpperRight.x);//�����Ļ��߱�
                //ndcNormal.x *= aspect;
                //pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                //o.pos = pos;
                //return o;

                // ʹ������������Ϊ��������
                //v2f o;
                //UNITY_INITIALIZE_OUTPUT(v2f, o);
                //float4 pos = UnityObjectToClipPos(v.vertex);
                ////float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal.xyz);
                //float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);
                //float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//�����߱任��NDC�ռ�
                //float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//�����ü������Ͻ�λ�õĶ���任���۲�ռ�
                //float aspect = abs(nearUpperRight.y / nearUpperRight.x);//�����Ļ��߱�
                //ndcNormal.x *= aspect;
                //pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy;
                //o.pos = pos;
                //return o;

                // ���������ɫ
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//�����߱任��NDC�ռ�
                float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//�����ü������Ͻǵ�λ�õĶ���任���۲�ռ�
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);//�����Ļ��߱�
                ndcNormal.x *= aspect;
                pos.xy += 0.01 * _OutlineWidth * ndcNormal.xy * v.vertColor.a;//����ɫaͨ�����ƴ�ϸ
                o.pos = pos;
                o.vertColor = v.vertColor.rgb;
                return o;

            }

            half4 frag(v2f i) : SV_TARGET
        {
                return fixed4(_OutLineColor * i.vertColor, 0);//����ɫrgbͨ�����������ɫ
            }
            ENDCG
        }
    }
}