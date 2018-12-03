Shader "ChineseInk/Filter"
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
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 normal = tex2D(_CameraDepthNormalsTexture, i.uv).xyz;
				float2 texel = _MainTex_TexelSize.xy;
				fixed3 col = tex2D(_MainTex,i.uv);

				float3 m0 = 0.0;  float3 m1 = 0.0;  
                float3 s0 = 0.0;  float3 s1 = 0.0;  
                float3 c; 

				for (int j = -4; j <= 0; ++j)  
                {  
                    for (int k = -4; k <= 0; ++k)  
                    {  
                        c = tex2D(_MainTex, i.uv +texel*float2(k, j)).xyz;
                        m0 += c;   
                        s0 += c * c;  
                    }  
                }
				for (int j = 0; j <= 4; ++j)  
                {  
                    for (int k = 0; k <= 4; ++k)  
                    {  
                        c = tex2D(_MainTex, i.uv +texel*float2(k, j)).xyz;
                        m1 += c;   
                        s1 += c * c;  
                    }  
                }
				//取方差小的区域的颜色作为最终输出颜色  
                float4 finalFragColor = 0.;  
                float min_sigma2 = 1e+2;                   
                m0 /= 25;  
                s0 = abs(s0 / 25 - m0 * m0);  
                float sigma2 = s0.r + s0.g + s0.b;  
                if (sigma2 < min_sigma2)   
                {  
                    min_sigma2 = sigma2;  
                    finalFragColor = float4(m0, 1.0);  
                }                     
                m1 /= 25  ;
                s1 = abs(s1 / 25 - m1 * m1);    
                sigma2 = s1.r + s1.g + s1.b;  
                if (sigma2 < min_sigma2)   
                {  
                    min_sigma2 = sigma2;  
                    finalFragColor = float4(m1, 1.0);  
                }

				return finalFragColor;
			}
			
			ENDCG
		}
	}
}
