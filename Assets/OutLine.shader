Shader "Unlit/OutLine"
{
	Properties{
	_Color("Color",Color)=(1,1,1,1)
	_EdgeColor("EdgeColor",Color)=(1,1,1,1)
	_EdgeFactor("EdgeFactor",Range(0,6))=3
	_Edgesize("Edgesize",Range(1,2))=1.01
	_MainTex("MainTex",2D)="white"{}
    }
	SubShader
	{
		
		//LOD 100

		Pass
		{
	    	Tags {"LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"  

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			struct a2v{
			float4 vertex :POSITION;
			float3 normal:NORMAL;
			float4 texcoord:TEXCOORD0;
			};
			struct v2f{
			float4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
			float3 worldNormal:TEXCOORD1;
			float4 worldPos:TEXCOORD2;
			};
			
			v2f vert(a2v v){
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);
			o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
			o.worldPos=mul(unity_ObjectToWorld,v.vertex);
			o.worldNormal=UnityObjectToWorldNormal(v.normal);
			return o;
			}
			fixed4 frag(v2f i):SV_Target{
			fixed3 worldNormal=normalize(i.worldNormal);
			fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.pos));
			
			fixed3 albedo=tex2D(_MainTex,i.uv).rgb*_Color.rgb;
			fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
			fixed3 diffuse=(_LightColor0.rgb)*albedo*max(0,dot(worldNormal,worldLightDir));
			return fixed4(ambient+diffuse,1.0);
			}
			
			ENDCG
		}
		
		Pass{
		    Tags{"LightMode"="ForwardBase"}		
		    Cull Front   //剔除正面
		    CGPROGRAM
            #pragma vertex vert
		    #pragma fragment frag
		    #include "UnityCG.cginc"  
		    
		    fixed4 _EdgeColor;
		    float   _EdgeFactor;
		    float _Edgesize;
		    
		     struct a2v{
			float4 vertex :POSITION;
			float3 normal:NORMAL;
			float4 texcoord:TEXCOORD0;
			};
			struct v2f{
			float4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
			float3 worldNormal:TEXCOORD1;
			float4 worldPos:TEXCOORD2;
			};
		    
		    float4 vert(appdata_base v):SV_POSITION{
		    v.vertex*=_Edgesize;
		    float4 pos=UnityObjectToClipPos(v.vertex);
		    float3 clipNormal=mul((float3x3)UNITY_MATRIX_MVP,v.normal);
		    pos.xy+=_EdgeFactor*clipNormal.xy;
		    return pos;
		    }
		    
		    fixed4 frag():SV_Target{	
			return _EdgeColor;
		    }
		    
		   
		
		    
		    ENDCG
		}
	}
	FallBack "Diffuse"
}
