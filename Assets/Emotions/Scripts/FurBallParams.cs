using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace FurBall
{
    //[System.Serializable]
    public class BaseParams : ScriptableObject
	{
        public float _Radius = 1;
        public Vector3 _EyeUVR;
        public float   _EyeScale;

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

    public class AniParams
	{
        public Vector3 _Pos = Vector3.zero;
        public Quaternion _Rot = Quaternion.identity;


        public float _Eye1Open = 1;
        public float _Eye2Open = 1;

	}

    public class FurBallParams : MonoBehaviour
    {
        public BaseParams _baseParams;


        Transform _trans;
        Transform trans
		{
            get
			{
                if(_trans==null)
				{
                    _trans = transform;
				}
                return _trans;
			}
		}

        Material _mat;
        Material mat
		{
            get
			{
                if(_mat==null)
				{
                    var mr = GetComponent<MeshRenderer>();
                    _mat = mr.sharedMaterial;
				}
                return _mat;
			}
		}

        [ContextMenu("SaveBaseParams")]
        void saveBaseParams()
		{

		}



		private void Update()
		{
			
		}

	}
}
