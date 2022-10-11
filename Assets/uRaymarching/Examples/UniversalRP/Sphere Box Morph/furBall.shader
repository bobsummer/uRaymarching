Shader "Unlit/furBall"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale ("UVScale", Range(1,5)) = 2
        _Radius ("Radius", Range(1,3)) = 1
        _FurDepth ("FurDepth", Range(0.1,0.8)) = 0.4
        _FurLayer ("FurLayer", Int) = 800
        _FurStepMulti("FurStepMulti",Range(2.0,5.0)) = 3.0
        _FurThreshold("FurThreshold",Range(0.1,0.9)) = 0.4
        _Shininess("Shiniess",Float) = 20

        _Eyeball_U_V_R("Eyeball_U_V_R",Vector) = (0.0,0.0,1.0)
        _EyeballRadius("EyeballRadius",Range(0.1,0.6)) = 0.3

        _EyelidThickness("EyelidThickness",Range(0.01,0.1)) = 0.05

        _UplidOffset("UplidOffset",Vector) = (0.0,-0.2,-0.0)
        _DownlidOffset("DownlidOffset",Vector) = (0.0,0.0,0.0)
        
        _Uplid_Start_Range("Uplid_Start_Range",Vector) = (-1.8,3.9) 
        _Downlid_Start_Range("Downlid_Start_Range",Vector) = (1.8,-3.9)

        _UpDownLid_XYRot("UpDownLid_XYRot",Vector) = (0.6,-0.6)

        _Iris_UV("Iris_UV",Vector) = (0.5,0.5)
        _IrisColor("IrisColor", Color) = (0.09,0.0315,0.0135)
        _IrisSize("IrisSize", Range(0.1,1.0))
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _FurDepth;

            float3 curl(float3 p,float3x3 tbn,float3 vel,float3 angular_vel)
            {
	            float r = length(p);
	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;

	            float3x3 inv_tbn = inverse(tbn);

	            float3 linear_vel = float3(0.0);

	            float len_anglular_axis = length(angular_vel);
	            if(len_anglular_axis>0.0)
	            {
		            float3 anglular_axis = angular_vel/len_anglular_axis;
		            float p_dot_axis = dot(p,anglular_axis);
		            float3 p_on_axis = p_dot_axis*anglular_axis;
		            float3 vR = p-p_on_axis;
		            linear_vel = cross(angular_vel,vR);
	            }

	            float3  vel_tbn = inv_tbn * vel;
	            vel_tbn *= 1.0;  //vel param

	            float3  linear_vel_tbn = inv_tbn * linear_vel;

	            linear_vel_tbn *= 0.03; //angular param
	            vel_tbn += linear_vel_tbn;

	            // float3 offset = cos(iTime*1.5)*t*t*0.4 * float3(0.0,1.0,0.0);
	            float3 offset = float3(vel_tbn.x,vel_tbn.y,0.0);
	            offset *= 0.2*t*t;
	            offset = tbn*offset;

	            // offset = float3(0.0);

	            p += offset;

	            return p;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
