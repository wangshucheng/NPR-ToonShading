Shader "Hidden/FragNormalShow"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
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

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float2 FragNormalMousePos;
			float4x4 MainVP;
			sampler2D _CameraGBufferTexture2;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				return o;
			}
			float4 GetWorldPositionFromDepthValue(float2 uv, float linearDepth)
			{
				float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

				// 假设相机投影区域的宽高比和屏幕一致。
				float height = 2 * camPosZ / unity_CameraProjection._m11;
				float width = _ScreenParams.x / _ScreenParams.y * height;
				float camPosX = width * uv.x - width / 2;
				float camPosY = height * uv.y - height / 2;
				float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
				return mul(unity_CameraToWorld, camPos);
			}
			fixed4 frag(v2f i) : SV_Target
			{

				float2 uv = i.uv.xy;

				 half2 startScPos = FragNormalMousePos;

				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, startScPos);
				depth = Linear01Depth(depth);
				half4 gbuffer2 = tex2D(_CameraGBufferTexture2, startScPos);
				half3 normalWorld = normalize(gbuffer2.rgb * 2 - 1);

				float3 wpos = GetWorldPositionFromDepthValue(startScPos,depth);

				float4 startSc = mul(MainVP, float4(wpos, 1));
				startSc /= startSc.w;
				startSc.xy = startSc.xy * 0.5 + 0.5;

				float4 endSc = mul(MainVP, float4(wpos + normalWorld,1));
				endSc /= endSc.w;
				endSc.xy = endSc.xy * 0.5 + 0.5;
				float2 normalSc = normalize(endSc.xy - startSc.xy);

				int show = acos(dot(normalSc, normalize(i.uv.xy - startSc.xy))) * length(i.uv.xy - startSc.xy) * _ScreenParams.xy < 1;
				show *= (length(i.uv.xy - startSc.xy) * _ScreenParams.xy < 200);

				return lerp(tex2D(_MainTex, i.uv), half4(0,1,0,1), show);


			}
			ENDCG
		}
	}
}