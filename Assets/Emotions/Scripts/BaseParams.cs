using System.Collections;
using UnityEngine;

namespace FurBall
{
    public class BaseParams : ScriptableObject
    {
        public float _Radius = 1;
        public Vector3 _EyeUVR;
        public float _EyeScale;

        [Range(-30.0f, 30.0f)]
        public float _ULid_XY_Rot_Deg = 0;
        [Range(-30.0f, 30.0f)]
        public float _DLid_XY_Rot_Deg = 0;

        [Range(-10.0f, 10.0f)]
        public float _ULid_YZ_Rot_Start_Deg = 0;
        [Range(-10.0f, 10.0f)]
        public float _DLid_YZ_Rot_Start_Deg = 0;

        [Range(-10.0f, 90.0f)]
        public float _ULid_YZ_Rot_Range_Deg = 80;
        [Range(-90.0f, 10.0f)]
        public float _DLid_YZ_Rot_Range_Deg = -80;

        public Color _FurColor = Color.white;
    }
}