#ifndef FURBLL_INCLUDED
#define FURBLL_INCLUDED

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
    return mat2(cc,-ss,ss,cc)*p;
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
    return float3(pndl) + float3(1.0,0.1,0.01)*0.7*pow(clamp(ir*0.75-nndl,0.0,1.0),2.0);
}

//perp distance
// <0 on ray's negatvie direction
// >0 on ray's positive direction
float dist_point_ray(float3 point,float3 ray_start,float3 ray_dir)
{
	float3 ray_pt = point-ray_start;
	float fDot = dot(ray_pt,ray_dir);
	float3 pt_on_ray = ray_start + ray_dir*fDot;
	return distance(point,pt_on_ray)*(fDot/abs(fDot));
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

struct transform
{
	float3 position;
	float3 rotation;
	float3 scale;
};

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

float3 localize(float3 p, transform tr)
{
	//Position
	p -= tr.position;

	//Rotation
	float3 x = rotate_x(p, radians(tr.rotation.x));
	float3 xy = rotate_y(x, radians(tr.rotation.y));
	float3 xyz = rotate_z(xy, radians(tr.rotation.z));
	p = xyz;

	//Scale
	p /= tr.scale;

	return p;
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
	uvr.xy = vec2(atan(p.z, p.x), acos(p.y));
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

#endif