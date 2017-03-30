Shader "HeatDistortion" 
{
	Properties 
	{
		_NoiseTex ("Noise Texture (RG)", 2D) = "white" {}
		_Instensity("Instensity", Range(0, 0.5)) = 0.6
		_Speed("Speed", Range(0, 1)) = 0.1
	}
	
	Category 
	{
		Tags { "Queue" = "Transparent+10" }
		SubShader
		{
			GrabPass
			{
				Tags { "LightMode" = "Always" }
			}
			
			Pass 
			{
				// no lighting is applied
				Tags { "LightMode" = "Always" }
				Fog { Color (0,0,0,0) }
				Lighting Off
				Cull Off
				ZWrite On
				ZTest LEqual
				Blend SrcAlpha OneMinusSrcAlpha
				AlphaTest Greater 0
				
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				
				sampler2D _GrabTexture;
				float4 _NoiseTex_ST;
				sampler2D _NoiseTex;
				float _Instensity;
				float _Speed;

				struct data {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
				};
				
				struct v2f {
					float4 position : POSITION;
					float4 uvgrab : TEXCOORD0;
					float2 uvmain : TEXCOORD2;
					float distortion : TEXCOORD1;
				};
				
				v2f vert(data i)
				{
					v2f o;
					o.position = mul(UNITY_MATRIX_MVP, i.vertex);
					o.uvmain = TRANSFORM_TEX(i.texcoord, _NoiseTex);
					float viewAngle = dot(normalize(ObjSpaceViewDir(i.vertex)), i.normal);
					o.distortion = viewAngle * viewAngle;
					float depth = -mul( UNITY_MATRIX_MV, i.vertex ).z;
					o.distortion /= 1 + depth;
					o.distortion *= _Instensity;

					//裁剪空间下 o.position的值范围在（-w 到 w）之间，经过ComputeGrabScreenPos后值范围在（0 - w）之间，
					//这里uvgrab没有标记POSITION，不会进行透视除法，需要在frag时手动进行透视除法
					o.uvgrab =  ComputeGrabScreenPos(o.position);
					return o;
				}
				
				half4 frag( v2f i ) : COLOR
				{
					half4 offsetColor1 = tex2D(_NoiseTex, i.uvmain + _Time * _Speed);
					half4 offsetColor2 = tex2D(_NoiseTex, i.uvmain - _Time * _Speed);

					//进行透视除法，将值范围从（0 - w）固定到 （0 - 1）,用于采样_GrabTexture
					float2 uv = i.uvgrab.xy / i.uvgrab.w;
					uv.x += ((offsetColor1.r + offsetColor2.r) - 1) * i.distortion;
					uv.y += ((offsetColor1.g + offsetColor2.g) - 1) * i.distortion;
					half4 col = tex2D( _GrabTexture, uv );
					return col;
				}
				
				ENDCG
			}
		}
	}
}
