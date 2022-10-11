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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

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

            // returns fur density at given position
            float furDensity(float3 pos, out float2 uv)
            {
	            float3x3 tbn;
	            posToTangentSpace(pos,tbn);

	            float3 vel = float3(-1.5*sin(1.5*iTime),-1.5*sin(1.5*iTime),0.0);
	            // vel = float3(0.0);
	            float3 angular_vel = float3(0.0,-30.0*2.2*sin(2.2*iTime),0.0);
	            // angular_vel = float3(0.0);

	            float3 nrm_pos = normalize(pos);
	            nrm_pos.x = abs(nrm_pos.x);

	            float3 blockball_pos = c_eyeball_pos+c_blockball_offset;

	            bool hit_left_eye = ray_intersect_sphere(float3(0.0),nrm_pos,blockball_pos,c_eyeball_radius*c_blockball_uvoffset_scale.z);
	            if(hit_left_eye)
	            {
		            return 0.0;
	            }
	            // bool hit_right_eye = ray_intersect_sphere(float3(0.0),nrm_pos,float3(-blockball_pos.x,blockball_pos.yz),c_eyeball_radius*c_eyeball_block_ratio);
	            // if(hit_right_eye)
	            // {
	            // 	return 0.0;
	            // }

	            pos = curl(pos,tbn,vel,angular_vel);

	            float3 uvr = cartesianToSpherical(pos,float3(0.0));
	            uv = uvr.xy;
	            float r = uvr.z;

	            float t = (r - (1.0 - furDepth)) / furDepth;
	            uv.y -= t*t*0.2;	// curl down

	            vec4 tex = textureLod(iChannel0, uv*uvScale, 0.0);
                // vec4 tex = vec4(1.0);

	            // thin out hair
	            float density = smoothstep(furThreshold, 1.0, tex.x);
	
	            // fade out along length
	            float len = tex.y;
	            density *= smoothstep(len, len-0.2, t);

	            return density;	
            }

            float3 furNormal(float3 pos, float density)
            {
                float eps = 0.01;
                float3 n;
	            float2 uv;
                n.x = furDensity( float3(pos.x+eps, pos.y, pos.z), uv ) - density;
                n.y = furDensity( float3(pos.x, pos.y+eps, pos.z), uv ) - density;
                n.z = furDensity( float3(pos.x, pos.y, pos.z+eps), uv ) - density;
                return normalize(n);
            }

            float3 furShade(float3 pos, float2 uv, float3 ro, float density)
            {
	            // lighting
	            const float3 L = float3(0, 1, 0);
	            float3 V = normalize(ro - pos);
	            float3 H = normalize(V + L);

	            float3 N = -furNormal(pos, density);
	            //float diff = max(0.0, dot(N, L));
	            float diff = max(0.0, dot(N, L)*0.5+0.5);
	            float spec = pow(max(0.0, dot(N, H)), shininess);
	            // spec = 0.0;
	
	            // base color
	            // float3 color = textureLod(iChannel1, uv*colorUvScale, 0.0).xyz;

                float3 color = float3(0.8,0.8,0.0);

	            // darken with depth
	            float r = length(pos);
	            float t = (r - (1.0 - furDepth)) / furDepth;
	            t = clamp(t, 0.0, 1.0);
	            float i = t*0.5+0.5;
		
	            return color*diff*i + float3(spec*i);
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
