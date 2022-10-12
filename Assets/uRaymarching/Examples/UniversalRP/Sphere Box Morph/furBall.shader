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

        _Eyeball_Pos_Scale("Eyeball_Pos_Scale",Vector) = (0.0,0.0,1.0,0.3)
        _BlockBall_Offset_Scale("BlockBall_Offset_Scale",Vector) = (0.0,0.0,0.0,0.8)

        _EyelidThickness("EyelidThickness",Range(0.01,0.1)) = 0.05

        _UplidOffset("UplidOffset",Vector) = (0.0,-0.2,-0.0)
        _DownlidOffset("DownlidOffset",Vector) = (0.0,0.0,0.0)
        
        _Uplid_Start_Range("Uplid_Start_Range",Vector) = (-1.8,3.9,0.0)
        _Downlid_Start_Range("Downlid_Start_Range",Vector) = (1.8,-3.9,0.0)

        _UpDownLid_XYRot("UpDownLid_XYRot",Vector) = (0.6,-0.6,0.0)

        _Iris_UV("Iris_UV",Vector) = (0.5,0.5,0.0)
        _IrisColor("IrisColor", Color) = (0.09,0.0315,0.0135)
        _IrisSize("IrisSize", Range(0.1,1.0)) = 0.8
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            // make fog work
            #pragma multi_compile_fog

            #include "./furBall.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings Vert(Attributes input)
            {
                Attributes output = (Attributes)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.postionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;  
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
                output.positionSS.z = -TransformWorldToView(output.positionWS).z;

                return output;
            }

            float  _UVScale;
            float  _Radius;
            float  _FurDepth;
            float  _FurThreshold;
            float4 _Eyeball_Pos_Scale; 
            float4 _BlockBall_Offset_Scale;
            float  _Shininess;

            float3 curl(float3 p,float3x3 tbn,float3 vel,float3 angular_vel)
            {
	            float r = length(p);
	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;

	            float3x3 inv_tbn = transpose(tbn);

	            float3 linear_vel = 0.0;

	            float len_anglular_axis = length(angular_vel);
	            if(len_anglular_axis>0.0)
	            {
		            float3 anglular_axis = angular_vel/len_anglular_axis;
		            float p_dot_axis = dot(p,anglular_axis);
		            float3 p_on_axis = p_dot_axis*anglular_axis;
		            float3 vR = p-p_on_axis;
		            linear_vel = cross(angular_vel,vR);
	            }

	            float3  vel_tbn = mul(inv_tbn,vel);
	            vel_tbn *= 1.0;  //vel param

	            float3  linear_vel_tbn = mul(inv_tbn,linear_vel);

	            linear_vel_tbn *= 0.03; //angular param
	            vel_tbn += linear_vel_tbn;

	            // float3 offset = cos(_Time.y*1.5)*t*t*0.4 * float3(0.0,1.0,0.0);
	            float3 offset = float3(vel_tbn.x,vel_tbn.y,0.0);
	            offset *= 0.2*t*t;
	            offset = mul(tbn,offset);

	            // offset = float3(0.0);

	            p += offset;

	            return p;
            }

            // returns fur density at given position
            float furDensity(float3 pos, out float2 uv)
            {
	            float3x3 tbn;
	            posToTangentSpace(pos,tbn);

	            float3 vel = float3(-1.5*sin(1.5* _Time.y),-1.5*sin(1.5* _Time.y),0.0);
	            // vel = float3(0.0);
	            float3 angular_vel = float3(0.0,-30.0*2.2*sin(2.2* _Time.y),0.0);
	            // angular_vel = float3(0.0);

	            float3 nrm_pos = normalize(pos);
	            nrm_pos.x = abs(nrm_pos.x);

	            float3 blockball_pos = _Eyeball_Pos_Scale.xyz+_BlockBall_Offset_Scale.xyz;

	            if(ray_intersect_sphere(0.0,nrm_pos,blockball_pos,_Radius*_Eyeball_Pos_Scale.w*_BlockBall_Offset_Scale.w))
	            {
		            return 0.0;
	            }

	            pos = curl(pos,tbn,vel,angular_vel);

	            float3 uvr = cartesianToSpherical(pos,0.0);
	            uv = uvr.xy;
	            float r = uvr.z;

	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;
	            uv.y -= t*t*0.2;	// curl down

	            float4 tex = tex2Dlod(_MainTex, float4(uv*_UVScale,0,0));
                // vec4 tex = vec4(1.0);

	            // thin out hair
	            float density = smoothstep(_FurThreshold, 1.0, tex.x);
	
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
	            float spec = pow(max(0.0, dot(N, H)), _Shininess);
	            // spec = 0.0;
	
	            // base color
	            // float3 color = textureLod(iChannel1, uv*colorUvScale, 0.0).xyz;

                float3 color = float3(0.8,0.8,0.0);

	            // darken with depth
	            float r = length(pos);
	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;
	            t = clamp(t, 0.0, 1.0);
	            float i = t*0.5+0.5;
		
	            return color*diff*i + spec*i;
            }
            
			float4 scene(inout RaymarchInfo ray)
			{
				float time = 0.0;
				vec3 p = vec3(0.0,0.0,0.0);

				// p = localize(p,trans);

				transform trans;
				trans.position = vec3(cos(iTime*1.5),cos(iTime*1.5),-2.0);
				// trans.scale = vec3(1.0);
				// trans.position = vec3(cos(iTime*1.2),0.0,0.0);
				trans.scale = vec3(1.0);
				trans.rotation = vec3(0.0);
				// trans.position = vec3(0.0);

				p = localize(p,trans);

				float t;				  
				bool hit = intersectSphere(ro+p, rd, _Radius, t);
				float start_t = t;
	
				vec4 c = vec4(0.0);
				if (hit) 
				{
					vec3 cma = vec3(0.0);
					float mat_ID = 0.0;

					vec3 pos = ro + rd*t;
					vec3 uvw = vec3(0.0);

					trans.rotation = vec3(0.01,cos(iTime*2.2)*30.0,0.0);
					// trans.rotation = vec3(0.0,(iTime*2.2)*30.0,0.0);
					// trans.rotation = vec3(0.1,10.0,0.0);

					vec2 mouse = iMouse.xy / iResolution.xy;
					float roty = 0.0;
					float rotx = 0.0;
					if (iMouse.z > 0.0) 
					{
						rotx = -(mouse.y-0.5)*300.0;
						roty = (mouse.x-0.5)*600.0;
						trans.rotation = vec3(rotx,roty,0.0);
					} 


					vec3 transed_pos = vec3(0.0);

					float hit_t = 0.0;

					for(int i=0; i<128;i++)
					{
						float tmp_matID = 0.0;

						transed_pos = localize(pos, trans);

						vec4 map_ret = map(transed_pos,time,tmp_matID,uvw);

						if(map_ret.x<0.001)
						{
							hit_t = t;
							cma = map_ret.yzw;
							mat_ID = tmp_matID;
							break;
						}

						t += map_ret.x*0.95;

						//todo cmp tmax to break

						pos = ro + t*rd;
					}

					bool eye_hitted = false;
					vec3 col = vec3(0.42);

					if(mat_ID>0.0)
					{
						vec3 pos = ro + t*rd;
						// vec3 transed_pos = localize(pos, trans);
						vec3 nor = calcNormal(transed_pos, time);

						// nor = vec3(1.0,1.0,0.0);

						float ks = 1.0;
						float se = 16.0;
						float tinterShadow = 0.0;
						float sss = 0.0;
						float focc = 1.0;

						if(mat_ID<1.5)
						{
							vec3 qos = vec3(abs(uvw.x),uvw.yz);

							// base skin color
							col = mix(vec3(0.225,0.15,0.12),
									vec3(0.24,0.1,0.066),
									smoothstep(0.4 ,0.0,length( qos.xy-vec2(0.42,-0.3)))+
									smoothstep(0.15,0.0,length((qos.xy-vec2(0,-0.29))/vec2(1.4,1))));
							// col = vec3(0.0);
							// fix that ugly highlight
							col -= 0.03*smoothstep(0.13,0.0,length((qos.xy-vec2(0,-0.49))/vec2(2,1)));
					

							// col = transed_pos;

							// fake skin drag
							uvw.y += 0.025*animData.x*smoothstep(0.3,0.1,length(uvw-vec3(0.0,0.1,1.0)));
							uvw.y -= 0.005*animData.y*smoothstep(0.09,0.0,abs(length((uvw.xy-vec2(0.0,-0.38))/vec2(2.5,1.0))-0.12));
				
							// fake occlusion
							focc = 0.2+0.8*pow(1.0-smoothstep(-0.4,1.0,uvw.y),2.0);
							focc *= 0.5+0.5*smoothstep(-1.5,-0.75,uvw.y);
							focc *= 1.0-smoothstep(0.4,0.75,abs(uvw.x));
							focc *= 1.0-0.4*smoothstep(0.2,0.5,uvw.y);
				
							focc *= 1.0-smoothstep(1.0,1.3,1.7*uvw.y-uvw.x);

							// col = vec3(0.0);
				
							//frsha = 0.0;
						}
						else if(mat_ID<2.5)
						{
							//eye
				
							// The eyes are fake in that they aren't 3D. Instead I simply
							// stamp a 2D mathematical drawing of an iris and pupil. That
							// includes the highlight and occlusion in the eyesballs.
							float sign_x = sign(transed_pos.x);

							vec2 animated_iris_uv = vec2(c_iris_uv.x,c_iris_uv.y+animData.x*0.1);

							vec3 iris_center_uvr = vec3(animated_iris_uv.xy,c_eyeball_radius);
							vec3 iris_pos = sphericalToCartesian(iris_center_uvr,vec3(0.0));
							vec3 hit_pos = transed_pos-vec3(sign_x*abs(c_eyeball_pos.x),c_eyeball_pos.yz);

							vec3 iris_pos_dir = normalize(iris_pos);

							float dot_hit = dot(hit_pos,iris_pos_dir);
							vec3 hit_proj_pos = dot_hit*iris_pos_dir;

							vec3 radius_delta = hit_pos-hit_proj_pos;

							float ss = sign(uvw.x);
				
							// iris
							float r = length(radius_delta);
							r *= c_iris_size;
							float a = atan(radius_delta.y,radius_delta.x);
							vec3 iris = c_iris_color;   //虹膜基础颜色
							iris += iris*3.0*(1.0-smoothstep(0.0,1.0, abs((a+PI)-2.5) ));  //虹膜不同角度带来的光泽变化
							iris *= 0.35+0.7*texture(iChannel0,vec2(r,a/PI2)).x;  //虹膜的条纹

							col *= 0.1+0.9*smoothstep(0.10,0.114,r); //虹膜边缘
							col = mix( col, iris, 1.0-smoothstep(0.095,0.10,r) ); //虹膜内部
							col *= smoothstep(0.05,0.07,r); //瞳孔
				
							// fake highlight 虹膜上的高光
							col += (0.5-1.0*0.3)*(1.0-smoothstep(0.0,0.02,length(hit_pos.xy-vec2(-0.05,0.05))));

							// fake occlusion
							focc = 0.2+0.8*pow(1.0-smoothstep(-0.4,1.0,uvw.y),2.0);
						}
						float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
						float occ = focc;

						// --------------------------
						// lighting. just four lights
						// --------------------------
						vec3 lin = vec3(0.0);

						// fake sss
						float nma = 0.0;

						//vec3 lig = normalize(vec3(0.5,0.4,0.6));
						vec3 lig = vec3(0.57,0.46,0.68); 
						vec3 hal = normalize(lig-rd);
						float dif = clamp( dot(nor,lig), 0.0, 1.0 );
						//float sha = 0.0; if( dif>0.001 ) sha=calcSoftshadow( pos+nor*0.002, lig, 0.0001, 2.0, time, 5.0 );
						float sha = 1.0;
						float spe = 2.0*ks*pow(clamp(dot(nor,hal),0.0,1.0),se)*dif*sha*(0.04+0.96*pow(clamp(1.0-dot(hal,-rd),0.0,1.0),5.0));

						// fake sss for key light
						vec3 cocc = mix(vec3(occ),
										vec3(0.1+0.9*occ,0.9*occ+0.1*occ*occ,0.8*occ+0.2*occ*occ),
										tinterShadow);
						cocc = mix( cocc, vec3(1,0.3,0.0), nma);
						sha = mix(sha,max(sha,0.3),nma);

						vec3  amb = cocc*(0.55 + 0.45*nor.y);
						float bou = clamp(0.3-0.7*nor.x, 0.0, 1.0 );

						lin +=      vec3(0.65,1.05,2.0)*amb*1.15;
						lin += 1.50*vec3(1.60,1.40,1.2)*sdif(dot(nor,lig),0.5+0.3*nma+0.2*(1.0-occ)*tinterShadow) * mix(vec3(sha),vec3(sha,0.2*sha+0.7*sha*sha,0.2*sha+0.7*sha*sha),tinterShadow);
						lin +=      vec3(1.00,0.30,0.1)*sss*fre*0.6*(0.5+0.5*dif*sha*amb)*(0.1+0.9*focc);
						lin += 0.35*vec3(4.00,2.00,1.0)*bou*occ*col;

						col = lin*col + spe + fre*fre*fre*0.1*occ;

						// c.xyz = (col.xxx + 1.0)*0.5;
						c.xyz = col;
						// c.z = 0.0;
						// c.y = 0.0;
						c.a = 1.0;
					}
					// else
			#ifdef OPEN_FUR
					{
						vec4 fur_col = vec4(0.0);
						t = start_t;
						pos = ro + rd*t;

						// ray-march into volume
						for(int i=0; i<furLayers; i++) 
						{
							// if(pos.z<=uvw.z)
							// {
							// 	break;
							// }
							vec4 sampleCol;
							vec2 uv;
							vec3 transed_pos = localize(pos, trans);
							// if(length(transed_pos)<=(1.0-furDepth))
							// {
							// 	break;
							// }
							if(mat_ID>0.0 && t>=hit_t)
							{
								break;
							}
							sampleCol.a = furDensity(transed_pos, uv);
							if (sampleCol.a > 0.0) 
							{
								sampleCol.rgb = furShade(transed_pos, uv, ro, sampleCol.a);

								// pre-multiply alpha
								sampleCol.rgb *= sampleCol.a;
								fur_col = fur_col + sampleCol*(1.0 - fur_col.a);
								if (fur_col.a > 0.95) 
								{
									break;
								}
							}				
							pos += rd*rayStep;
							t += rayStep;
						}

						c.xyz = fur_col.rgb*fur_col.a + c.rgb*(1.0-fur_col.a);
						// c.xyz = fur_col.rgb*(1.0-c.a) + c.rgb*c.a;
						// c.rgb = fur_col.rgb;
					}
			#endif
				}
	
	return c;
}

            FragOutput Frag (Varyings input) : SV_Target
            {
                RaymarchInfo ray;

                InitRaymarchObject(ray,input.postionSS,input.postionWS,input.normalWS);

                ray.maxLoop = 512;
                ray.minDistance = 0.01;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL
        }
    }
}
