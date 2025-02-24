#ifndef FURBLL_INCLUDED
#define FURBLL_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

//#define PI  3.14159
//#define PI2 PI*2.0

inline float sdSphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

float linearstep(float a, float b, in float x )
{
    return clamp( (x-a)/(b-a), 0.0, 1.0 );
}

float2 rot( in float2 p, in float an )
{
    float cc = cos(an);
    float ss = sin(an);
    return mul(float2x2(cc,-ss,ss,cc),p);
}

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    k *= 1.4;
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*h/(6.0*k*k);
}

float3 sdif( float ndl, float ir )
{
    float pndl = clamp( ndl, 0.0, 1.0 );
    float nndl = clamp(-ndl, 0.0, 1.0 );
    return float3(pndl.xxx) + float3(1.0,0.1,0.01)*0.7*pow(clamp(ir*0.75-nndl,0.0,1.0),2.0);
}

//perp distance
// <0 on ray's negatvie direction
// >0 on ray's positive direction
float dist_point_ray(float3 pt,float3 ray_start,float3 ray_dir)
{
	float3 ray_pt = pt-ray_start;
	float fDot = dot(ray_pt,ray_dir);
	float3 pt_on_ray = ray_start + ray_dir*fDot;
	return distance(pt,pt_on_ray)*(fDot/abs(fDot));
}

bool ray_intersect_sphere(float3 ray_start,float3 ray_dir,float3 sphere_center,float sphere_radius)
{
	float dist = dist_point_ray(sphere_center,ray_start,ray_dir);
	if(dist<0.0)
	{
		return false;
	}
	else
	{
		return dist<=sphere_radius;
	}
}

float3 rotate_x(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
}

float3 rotate_y(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
}

float3 rotate_z(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
}

bool intersectSphere(float3 ro, float3 rd, float r, out float t)
{
	float b = dot(-ro, rd);
	float det = b*b - dot(ro, ro) + r*r;
	if (det < 0.0) return false;
	det = sqrt(det);
	t = b - det;
	return t > 0.0;
}

void posToTangentSpace(float3 p,out float3x3 tbn)
{
	float3 n = normalize(p);
	float3 up = float3(0.0,1.0,0.0);
	float3 t = cross(up,n);
	t = normalize(t);
	float3 b = cross(n,t);
	b = normalize(b);
	tbn[0].xyz = t;
	tbn[1].xyz = b;
	tbn[2].xyz = n;
}

float3 cartesianToSpherical(float3 p,float3 center)
{
	float3 uvr;		
	uvr.z = length(p);
	p /= uvr.z;
	uvr.xy = float2(atan2(p.z, p.x), acos(p.y));
	return uvr;
}

float3 sphericalToCartesian(float3 uvr,float3 center)
{
	float3 pos;

	uvr.x = clamp(uvr.x,0.0,1.0);
	uvr.y = clamp(uvr.y,0.0,1.0);
	uvr.x *= 1.0*PI;
	uvr.y *= PI;

	pos.x = sin(uvr.y)*cos(uvr.x);
	pos.z = sin(uvr.y)*sin(uvr.x);
	pos.y = cos(uvr.y);
	pos *= uvr.z;
	pos += center;
	return pos;
}

struct RaymarchInfo
{
    // Input
    float3 startPos;
    float3 rayDir;
	float3 polyPos;
    float3 polyNormal;
    float4 projPos;
    float minDistance;
    float maxDistance;
    int maxLoop;

    // Output
    int loop;
    float3 endPos;
    float lastDistance;
    float totalLength;
    float depth;
    float3 normal;
};

inline float3 GetCameraPosition()    
{ 
	return UNITY_MATRIX_I_V._m03_m13_m23; 
}

inline float3 GetCameraRight()
{
	return UNITY_MATRIX_I_V._m00_m10_m20;
}

inline float3 GetCameraUp()
{
	return UNITY_MATRIX_I_V._m01_m11_m21;
}

inline float3 GetCameraForward()
{
	return UNITY_MATRIX_I_V._m02_m12_m22; 
}

inline float  GetCameraFarClip()     
{ 
	return _ProjectionParams.z;       
}

inline float4x4 GetHClipToWorldMatrix()
{
	return _InvViewProjMatrix;
}

inline float3 TransformHClipToWorld(float4 positionCS)
{
     //float4 retPositionWorld = mul(GetHClipToWorldMatrix(), positionCS);
	 //return retPositionWorld.xyz/retPositionWorld.w;
	 float4 retPositionWorld =  mul(unity_MatrixInvV , mul(unity_MatrixInvP,positionCS));
	 return retPositionWorld.xyz;
}

inline void InitRaymarchObject(out RaymarchInfo ray, float4 positionSS, float3 positionWS, float4 positionCS, float3 normalWS, float2 offset)
{
    ray = (RaymarchInfo)0;

	float4 newPostionCS = TransformWorldToHClip(positionWS);

	float4 offseted_positionCS = newPostionCS;
	//offseted_positionCS += offset.x;
	//offseted_positionCS += offset.y;

	float4 screenParams = GetScaledScreenParams();

	offset.xy /= screenParams.xy;

	offseted_positionCS.xyz /= offseted_positionCS.w;

	offseted_positionCS.xy += offset;

	offseted_positionCS.xyz *= offseted_positionCS.w;

	//float3 offseted_positionWS = positionWS;
	//offseted_positionWS += GetCameraRight()*offset.x;
	//offseted_positionWS += GetCameraUp()*offset.y;

	float3 offseted_positionWS = TransformHClipToWorld(offseted_positionCS);
	//offseted_positionWS.z = positionWS.z;

    ray.rayDir = normalize(offseted_positionWS - GetCameraPosition());

    ray.projPos = positionSS;
    ray.startPos = GetCameraPosition();
    ray.polyPos = positionWS;
    ray.polyNormal = normalize(normalWS);
    ray.maxDistance = GetCameraFarClip();
}

inline float3 PosToLocal(float3 pos)
{
    //return mul(GetWorldToObjectMatrix(), float4(pos, 1.0)).xyz;
	return TransformWorldToObject(pos);
}

inline float3 DirToLocal(float3 dir,bool doNormalize = false)
{
	return TransformWorldToObjectDir(dir,doNormalize);
}

inline float3 WorldPos()
{
	return GetObjectToWorldMatrix()._m03_m13_m23;
}

inline float4 ComputeNonStereoScreenPos(float4 pos)
{
    float4 o = pos * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = pos.zw;
    return o;
}

#endif