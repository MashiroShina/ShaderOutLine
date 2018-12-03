Shader "ChineseInk/Edge"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "black" {}
		_EdgeWidth("Edge Width",Float) = 1
		_EdgeColor("Edge Color",Color) = (0,0,0,1)
		_Sensitive("_Sensitive",Range(0,1)) = 0.9
		
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			uniform sampler2D_float _CameraDepthNormalsTexture;
			sampler2D _CameraDepthTexture;

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

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			#define MOD3 float3(.1031,.11369,.13787)
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _NoiseTex;
			half4 _NoiseTex_TexelSize;
			float _EdgeWidth;
			fixed4 _EdgeColor;
			fixed _Sensitive;

			float4 GetWorldPositionFromDepthValue( float2 uv, float linearDepth )   
            {  
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;  
                float height = 2 * camPosZ / unity_CameraProjection._m11;  
                float width = _ScreenParams.x / _ScreenParams.y * height;  
  
                float camPosX = width * uv.x - width / 2;  
                float camPosY = height * uv.y - height / 2;  
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);  
                return mul(unity_CameraToWorld, camPos);  
            }
			float rgb2gray(fixed3 col){
				float gray = 0.2125 * col.r + 0.7154 * col.g + 0.0721 * col.b; 
				return gray;
			}
			float hash31(float3 p3)
			{
				p3  = frac(p3 * MOD3);
				p3 += dot(p3, p3.yzx + 19.19);
				return -1.0 + 2.0 * frac((p3.x + p3.y) * p3.z);
			}
			float mix(float a,float b,float c){
				return a*(1-c) + b*c;
			}
			float value_noise(float3 p)
			{
				float3 pi = floor(p);
				float3 pf = p - pi;
    
				float3 w = pf * pf * (3.0 - 2.0 * pf);
    
				return 	mix(
        					mix(
        						mix(hash31(pi + float3(0, 0, 0)), hash31(pi + float3(1, 0, 0)), w.x),
        						mix(hash31(pi + float3(0, 0, 1)), hash31(pi + float3(1, 0, 1)), w.x), 
								w.z),
        					mix(
								mix(hash31(pi + float3(0, 1, 0)), hash31(pi + float3(1, 1, 0)), w.x),
        						mix(hash31(pi + float3(0, 1, 1)), hash31(pi + float3(1, 1, 1)), w.x), 
								w.z),
        					w.y);
			}
			fixed4 frag (v2f i) : SV_Target
			{							
				float2 texel = _MainTex_TexelSize.xy;
				fixed3 col = tex2D(_MainTex,i.uv);
				//判断是否是边缘
				fixed3 col0 = tex2D(_CameraDepthNormalsTexture,i.uv+_EdgeWidth*texel*float2(1,1)).xyz;
				fixed3 col1 = tex2D(_CameraDepthNormalsTexture,i.uv+_EdgeWidth*texel*float2(1,-1)).xyz;
				fixed3 col2 = tex2D(_CameraDepthNormalsTexture,i.uv+_EdgeWidth*texel*float2(-1,1)).xyz;
				fixed3 col3 = tex2D(_CameraDepthNormalsTexture,i.uv+_EdgeWidth*texel*float2(-1,-1)).xyz;
				float edge = rgb2gray(pow(col0-col3,2)+pow(col1-col2,2));

								
				float dep = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				float linearDepth = Linear01Depth(dep);
				float3 worldPos = GetWorldPositionFromDepthValue(i.uv,linearDepth).xyz;
				
				//添加噪声				
				float noise = value_noise(float3(worldPos*2))+0.5*value_noise(float3(worldPos*4))
				+0.25*value_noise(float3(worldPos*8))+0.125*value_noise(float3(worldPos*16));
				noise = noise/3.75+0.5;

				
				edge = pow(edge,0.2);
				if(edge <= _Sensitive)edge=0;				
				else{
					edge=noise;
				}

				if(dep<0.001)noise = 0;

				fixed3 finalColor = (edge)*_EdgeColor.xyz+(1-edge)*col*(0.95+0.1*noise);			
				return fixed4(finalColor,1.0);
				
			}
			
			ENDCG
		}
	}
}
