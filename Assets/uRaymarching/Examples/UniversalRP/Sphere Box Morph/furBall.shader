Shader "Unlit/furBall"
{
    Properties
    {
		[Header(Base)]
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale ("UVScale", Range(1,5)) = 2
        _Radius ("Radius", Range(0.1,0.5)) = 0.5
        _FurDepth ("FurDepth", Range(0.1,0.8)) = 0.4
		_FurDepthScale ("_FurDepthScale", Int) = 3
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
		_HighlightOffset("HighlightOffset",Vector) = (-0.05,0.05,0.0)

		[Header(Pass)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
		[Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1
    }
    SubShader
    {
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderPipeline" = "UniversalPipeline"
			"DisableBatching" = "True"
		}
        LOD 100

        Pass
        {

			Blend[_BlendSrc][_BlendDst]
			ZWrite[_ZWrite]
			Cull[_Cull]

            HLSLPROGRAM

			#define OPEN_FUR

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
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;  
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionSS = ComputeNonStereoScreenPos(output.positionCS);
                output.positionSS.z = -TransformWorldToView(output.positionWS).z;

                return output;
            }

            float  _UVScale;
            float  _Radius;
            float  _FurDepth;
			int    _FurDepthScale;
            float  _FurThreshold;
			int    _FurLayer;
            float4 _Eyeball_Pos_Scale; 
            float4 _BlockBall_Offset_Scale;
            float  _Shininess;
			float  _EyelidThickness;
			float3 _UplidOffset;
			float3 _DownlidOffset;
			float2 _UpDownLid_XYRot;
			float2 _Uplid_Start_Range;
			float2 _Downlid_Start_Range;
			float2 _Iris_UV;
			float  _IrisSize;
			float4 _IrisColor;
			float2 _HighlightOffset;

			float3 animData;			

            float3 curl(float3 p,float3x3 tbn,float3 vel,float3 angular_vel)
            {
	            float r = length(p);
				r /= _Radius;
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
	            vel = 0.0;
	            float3 angular_vel = float3(0.0,-30.0*2.2*sin(2.2* _Time.y),0.0);
	            angular_vel = 0.0;

	            float3 nrm_pos = normalize(pos);
	            nrm_pos.x = abs(nrm_pos.x);

	            float3 blockball_pos = _Eyeball_Pos_Scale.xyz+_BlockBall_Offset_Scale.xyz;
				blockball_pos *= _Radius;

	            if(ray_intersect_sphere(0.0,nrm_pos,blockball_pos,_Radius*_Eyeball_Pos_Scale.w*_BlockBall_Offset_Scale.w))
	            {
		            return 0.0;
	            }

	            //pos = curl(pos,tbn,vel,angular_vel);

	            float3 uvr = cartesianToSpherical(pos,0.0);
	            uv = uvr.xy;
	            float r = uvr.z;
				r /= _Radius;

	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;
	            uv.y -= t*t*0.2;	// curl down

	            float4 tex = tex2Dlod(_MainTex, float4(uv*_UVScale,0,0));
                // float4 tex = float4(1.0);

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
				r /= _Radius;
	            float t = (r - (1.0 - _FurDepth)) / _FurDepth;
	            t = clamp(t, 0.0, 1.0);
	            float i = t*0.5+0.5;
		
	            return color*diff*i + spec*i;
            }

			float4 map(in float3 pos,in float time,out float outMat,out float3 uvw)
			{
				//symmetric coord system
				float3 qos = float3(abs(pos.x),pos.yz); //sharp
				// float3 sos = float3(sqrt(qos.x*qos.x+0.0005),pos.yz); //smooth

				float d = sdSphere(pos,(1.0-_FurDepth)*_Radius);

				float4 ret = 0.0;

				ret.x = d;
				outMat = 1.0;
				uvw = pos;

				//return ret;
	
				//eyelid
				float3 oos = qos - _Eyeball_Pos_Scale.xyz*_Radius;
				float d2 = sdSphere(oos,_Radius*(_Eyeball_Pos_Scale.w + _EyelidThickness));
	
				oos += _UplidOffset * _Radius;

				// oos.z += 0.2;
				// oos.y += -0.0;

				oos.xy = rot(oos.xy, _UpDownLid_XYRot.x);
				oos.yz = rot(oos.yz,_Uplid_Start_Range.x+_Uplid_Start_Range.y*animData.x);

				float3 eos = qos - _Eyeball_Pos_Scale.xyz*_Radius;

				eos += _DownlidOffset * _Radius;
				eos.xy = rot(eos.xy, _UpDownLid_XYRot.y);
				eos.yz = rot(eos.yz,_Downlid_Start_Range.x+_Downlid_Start_Range.y*animData.x);

				d2 = smax(d2-0.005*_Radius, -max(oos.y+0.098*_Radius,-eos.y-0.025*_Radius), 0.06*_Radius );
				d2 = smin(d2,d,0.1*_Radius);
				// d2 = min(d2,d);

				//d2 = d;

				ret.x = d2;
				outMat = 1.0;
				uvw = pos;

				// return ret;

				//eyeball
				// pos.x /= 1.05;
				eos = qos-_Eyeball_Pos_Scale.xyz*_Radius;
				d = sdSphere(eos,_Eyeball_Pos_Scale.w*_Radius);

				if(d<ret.x)
				{
					ret.x = d;
					outMat = 2.0;
					uvw = eos;
				}
				// d = smin( d, d2, 0.012 );
				return ret;
			}

			float4 mapD( in float3 pos, in float time )
			{
				float matID;
				float3 uvw;
				float4 h = map(pos, time, matID, uvw);   
				return h;
			}

			float3 calcNormal( in float3 pos, in float time )
			{
				const float eps = 0.001;

				float4 n = 0.0;
				for( int i=0; i<4; i++ )
				{
					float4 s = float4(pos, 0.0);
					float kk; float3 kk2;
					s[i] += eps;
					n[i] = mapD(s.xyz, time).x;
				}
				return normalize(n.xyz-n.w);
			}

			float animBlink( in float time, in float smo )
			{
				// head-turn motivated blink
				const float w = 6.1;
				float t = fmod(time-0.31,w*1.0);
				float blink = smoothstep(0.0,0.1,t) - smoothstep(0.18,0.4,t);

				// regular blink
				float tt = fmod(1.0+time,3.0);
				blink = max(blink,smoothstep(0.0,0.07+0.07*smo,tt)-smoothstep(0.1+0.04*smo,0.35+0.3*smo,tt));
    
				// keep that eye alive always
				float blinkBase = 0.04*(0.5+0.5*sin(time));
				blink = lerp( blinkBase, 1.0, blink );

				// base pose is a bit down
				float down = 0.15;
				return down+(1.0-down)*blink;
			}
            
			float4 scene(inout RaymarchInfo ray)
			{
				float3 localRayStart = PosToLocal(ray.startPos);
				float3 localRayDir = DirToLocal(ray.rayDir,true);

				float t;				  
				bool hit = intersectSphere(localRayStart, localRayDir, _Radius, t);
				float start_t = t;

				float time = _Time.y;				
	
				float4 c = 0.0;
				if (hit) 
                {
					//return 1;
					float3 cma = 0.0;
					float mat_ID = 0.0;
					float3 pos = localRayStart + localRayDir*t;
					float3 uvw = 0.0;
					float hit_t = 0.0;

					for(int i=0; i<128;i++)
					{
						float tmp_matID = 0.0;
						float4 map_ret = map(pos,time,tmp_matID,uvw);
						if(map_ret.x<0.001)
						{
							hit_t = t;
							cma = map_ret.yzw;
							mat_ID = tmp_matID;
							break;
						}
						t += map_ret.x*0.95;
						pos = localRayStart + localRayDir*t;
					}

					bool eye_hitted = false;
					float3 col = 0.42;

					if(mat_ID>0.0)
					{
						pos = localRayStart + localRayDir*t;
						float3 nor = calcNormal(pos, time);

						float ks = 1.0;
						float se = 16.0;
						float tinterShadow = 0.0;
						float sss = 0.0;
						float focc = 1.0;

						if(mat_ID<1.5)
						{
							float3 qos = float3(abs(uvw.x),uvw.yz);

							// base skin color
							col = lerp(float3(0.225,0.15,0.12),
									float3(0.24,0.1,0.066),
									smoothstep(0.4 ,0.0,length( qos.xy-float2(0.42,-0.3)))+
									smoothstep(0.15,0.0,length((qos.xy-float2(0,-0.29))/float2(1.4,1))));
							// fix that ugly highlight
							col -= 0.03*smoothstep(0.13,0.0,length((qos.xy-float2(0,-0.49))/float2(2,1)));					

							// fake skin drag
							uvw.y += 0.025*animData.x*smoothstep(0.3,0.1,length(uvw-float3(0.0,0.1,1.0)));
							uvw.y -= 0.005*animData.y*smoothstep(0.09,0.0,abs(length((uvw.xy-float2(0.0,-0.38))/float2(2.5,1.0))-0.12));
				
							// fake occlusion
							focc = 0.2+0.8*pow(1.0-smoothstep(-0.4,1.0,uvw.y),2.0);
							focc *= 0.5+0.5*smoothstep(-1.5,-0.75,uvw.y);
							focc *= 1.0-smoothstep(0.4,0.75,abs(uvw.x));
							focc *= 1.0-0.4*smoothstep(0.2,0.5,uvw.y);
				
							focc *= 1.0-smoothstep(1.0,1.3,1.7*uvw.y-uvw.x);

							//col = 0.0;
				
							//frsha = 0.0;
						}
						else if(mat_ID<2.5)
						{
							//eye
				
							// The eyes are fake in that they aren't 3D. Instead I simply
							// stamp a 2D mathematical drawing of an iris and pupil. That
							// includes the highlight and occlusion in the eyesballs.
							float sign_x = sign(pos.x);

							float2 animated_iris_uv = float2(_Iris_UV.x,_Iris_UV.y+animData.x*0.1);

							float3 iris_center_uvr = float3(animated_iris_uv.xy,_Radius*_Eyeball_Pos_Scale.w);
							float3 iris_pos = sphericalToCartesian(iris_center_uvr,0.0);
							float3 hit_pos = pos-float3(sign_x*abs(_Eyeball_Pos_Scale.x),_Eyeball_Pos_Scale.yz)*_Radius;

							float3 iris_pos_dir = normalize(iris_pos);

							float dot_hit = dot(hit_pos,iris_pos_dir);
							float3 hit_proj_pos = dot_hit*iris_pos_dir;

							float3 radius_delta = hit_pos-hit_proj_pos;

							float ss = sign(uvw.x);
				
							// iris
							float r = length(radius_delta);
							r *= _IrisSize/_Radius;
							float a = atan2(radius_delta.y,radius_delta.x);
							float3 iris = _IrisColor;   //虹膜基础颜色
							iris += iris*3.0*(1.0-smoothstep(0.0,1.0, abs((a+PI)-2.5) ));  //虹膜不同角度带来的光泽变化
							iris *= 0.35+0.7*tex2D(_MainTex,float2(r,a/(PI*2))).x;       //虹膜的条纹

							col *= 0.1+0.9*smoothstep(0.10,0.114,r); //虹膜边缘
							col = lerp( col, iris, 1.0-smoothstep(0.095,0.10,r) ); //虹膜内部
							col *= smoothstep(0.05,0.07,r); //瞳孔
				
							// fake highlight 虹膜上的高光
							col += (0.5-1.0*0.3)*(1.0-smoothstep(0.0,0.02*_Radius,length(hit_pos.xy-_HighlightOffset*_Radius)));

							// fake occlusion
							focc = 0.2+0.8*pow(1.0-smoothstep(-0.4,1.0,uvw.y),2.0);
						}
						float fre = clamp(1.0+dot(nor,localRayDir),0.0,1.0);
						float occ = focc;

						// --------------------------
						// lighting. just four lights
						// --------------------------
						float3 lin = 0.0;

						// fake sss
						float nma = 0.0;

						//float3 lig = normalize(float3(0.5,0.4,0.6));
						float3 lig = float3(0.57,0.46,0.68); 
						float3 hal = normalize(lig-localRayDir);
						float dif = clamp( dot(nor,lig), 0.0, 1.0 );
						//float sha = 0.0; if( dif>0.001 ) sha=calcSoftshadow( pos+nor*0.002, lig, 0.0001, 2.0, time, 5.0 );
						float sha = 1.0;
						float spe = 2.0*ks*pow(clamp(dot(nor,hal),0.0,1.0),se)*dif*sha*(0.04+0.96*pow(clamp(1.0-dot(hal,-localRayDir),0.0,1.0),5.0));

						// fake sss for key light
						float3 cocc = lerp(occ,
										float3(0.1+0.9*occ,0.9*occ+0.1*occ*occ,0.8*occ+0.2*occ*occ),
										tinterShadow);
						cocc = lerp( cocc, float3(1,0.3,0.0), nma);
						sha = lerp(sha,max(sha,0.3),nma);

						float3 amb = cocc*(0.55 + 0.45*nor.y);
						float bou = clamp(0.3-0.7*nor.x, 0.0, 1.0 );

						lin +=      float3(0.65,1.05,2.0)*amb*1.15;
						lin += 1.50*float3(1.60,1.40,1.2)*sdif(dot(nor,lig),0.5+0.3*nma+0.2*(1.0-occ)*tinterShadow) * lerp(sha,float3(sha,0.2*sha+0.7*sha*sha,0.2*sha+0.7*sha*sha),tinterShadow);
						lin +=      float3(1.00,0.30,0.1)*sss*fre*0.6*(0.5+0.5*dif*sha*amb)*(0.1+0.9*focc);
						lin += 0.35*float3(4.00,2.00,1.0)*bou*occ*col;

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
						float4 fur_col = 0;
						t = start_t;
						pos = localRayStart + localRayDir*t;

						float rayStep = _FurDepth*(float)_FurDepthScale*_Radius/(float)(_FurLayer);

						// ray-march into volume
						for(int i=0; i<_FurLayer; i++) 
						{
							float4 sampleCol;
							float2 uv;

							if(mat_ID>0.0 && t>=hit_t)
							{
								break;
							}

							sampleCol.a = furDensity(pos, uv);

							//sampleCol = float4(1,0,0,1);
							if (sampleCol.a > 0.0) 
							{
								sampleCol.rgb = furShade(pos, uv, localRayStart, sampleCol.a);

								// pre-multiply alpha
								sampleCol.rgb *= sampleCol.a;
								fur_col = fur_col + sampleCol*(1.0 - fur_col.a);
								if (fur_col.a > 0.95) 
								{
									break;
								}
							}				
							pos += localRayDir*rayStep;
							t += rayStep;
						}

						c.xyz = fur_col.rgb*fur_col.a + c.rgb*(1.0-fur_col.a);
						c.a = fur_col.a*fur_col.a + c.a*(1.0-fur_col.a);
						//c.a = 1;
						// c.xyz = fur_col.rgb*(1.0-c.a) + c.rgb*c.a;
						//c.rgb = fur_col.rgb;
						//c = fur_col;
					}
#endif
				}	
				return c;
			}

			float4 Frag(Varyings input) : SV_Target
			{
				float turn = 0.0;

				animData.x = animBlink(_Time.y,0.0);
        		animData.y = animBlink(_Time.y-0.02,1.0);
        		// animData.y = 0.0;
        		animData.z = -0.25 + 0.2*(1.0-turn)*smoothstep(-0.3,0.9,sin(_Time.y*1.1)) + 0.05*cos(_Time.y*2.7);

                RaymarchInfo ray;

                InitRaymarchObject(ray,input.positionSS,input.positionWS,input.normalWS);

                ray.maxLoop = 512;
                ray.minDistance = 0.01;

                // sample the texture
                float4 col = scene(ray);
				//col = 1;
                return col;
            }
            ENDHLSL
        }
    }
}
