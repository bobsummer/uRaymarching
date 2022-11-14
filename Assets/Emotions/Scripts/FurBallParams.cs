using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using FFUtils;
using System.Reflection;
using System;

namespace FurBall
{
    //[System.Serializable]
    public class AnimationParams
	{
        public Vector3 _Pos = Vector3.zero;
        public Quaternion _Rot = Quaternion.identity;

        public float _Eye1Open = 1;
        public float _Eye2Open = 1;
	}

    public class MatNameIDs
	{
        public MatNameIDs()
		{
            Mat_NameID.fillFields(this);
        }

        public Mat_NameID _Radius;
        public Mat_NameID _Eyeball_Pos_Scale;
        public Mat_NameID _EyelidThickness;
        public Mat_NameID _UpDownLid_XYRot;
        public Mat_NameID _Uplid_Start_Range;
        public Mat_NameID _Downlid_Start_Range;
        public Mat_NameID _FurColor;

        public Mat_NameID _Eye1Open;
        public Mat_NameID _Eye2Open;
    }

    public class FurBallParams : MonoBehaviour
    {
        public string _Path;
        public string _BaseParamsName;
        public BaseParams _BaseParams;

        public FaceAnimation _BindFaceAnimation;

        private AnimationParams _AniParams = new AnimationParams();
        private MatNameIDs _MatNameIDs;


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
                    _mat = mr.material;
				}
                return _mat;
			}
		}

        [ContextMenu("NewBaseParams")]
        void newBaseParams()
		{
            _BaseParams = ScriptableObject.CreateInstance<BaseParams>();
		}

        [ContextMenu("SaveBaseParams")]
        void saveBaseParams()
		{
            if(_BaseParams==null)
			{
                return;
			}
            if(AssetDatabase.Contains(_BaseParams))
			{
                AssetDatabase.SaveAssets();
			}
            else
			{
                saveBaseParamsAs();
			}
		}

        [ContextMenu("SaveBaseParamsAs")]
        void saveBaseParamsAs()
		{
            if(AssetDatabase.Contains(_BaseParams))
			{
                _BaseParams = Instantiate(_BaseParams);
			}
            string fullPath = _Path + "/"  + _BaseParamsName + ".asset";
            int idx = 1;
            while(true)
			{
                var guid = AssetDatabase.AssetPathToGUID(fullPath, AssetPathToGUIDOptions.OnlyExistingAssets);
                if (guid == null || guid.Length <= 0)
                {
                    break;
                }
                fullPath = _Path + "/" + _BaseParamsName + "_" + idx.ToString() + ".asset";
                idx++;
            }
            AssetDatabase.CreateAsset(_BaseParams, fullPath);
        }

        void syncBaseParams()
		{
            mat.SetFloat(_MatNameIDs._Radius.ID, _BaseParams._Radius);

			{
                Vector4 eye_Pos_Scale = Maths.sphericalToCartesian(_BaseParams._EyeUVR, Vector3.zero);
                eye_Pos_Scale.w = _BaseParams._EyeScale;
                mat.SetVector(_MatNameIDs._Eyeball_Pos_Scale.ID, eye_Pos_Scale);
                mat.SetFloat(_MatNameIDs._EyelidThickness.ID, _BaseParams._LidThickness);
            }

			{
                Vector4 lidXYRotRads = Vector4.zero;
                lidXYRotRads.x = _BaseParams._ULid_XY_Rot_Deg * Mathf.Deg2Rad;
                lidXYRotRads.y = _BaseParams._DLid_XY_Rot_Deg * Mathf.Deg2Rad;
                mat.SetVector(_MatNameIDs._UpDownLid_XYRot.ID, lidXYRotRads);
            }

			{
                Vector4 u_lid_start_range = Vector4.zero;
                Vector4 d_lid_start_range = Vector4.zero;
                u_lid_start_range.x = _BaseParams._ULid_YZ_Rot_Start_Deg * Mathf.Deg2Rad;
                u_lid_start_range.y = _BaseParams._ULid_YZ_Rot_Range_Deg * Mathf.Deg2Rad;
                d_lid_start_range.x = _BaseParams._DLid_YZ_Rot_Start_Deg * Mathf.Deg2Rad;
                d_lid_start_range.y = _BaseParams._DLid_YZ_Rot_Range_Deg * Mathf.Deg2Rad;
                mat.SetVector(_MatNameIDs._Uplid_Start_Range.ID, u_lid_start_range);
                mat.SetVector(_MatNameIDs._Downlid_Start_Range.ID, d_lid_start_range);
            }

            mat.SetColor(_MatNameIDs._FurColor.ID, _BaseParams._FurColor);
		}

        static bool face_to_furball_animation(FaceAnimation faceAni,ref AnimationParams aniParams)
		{
            bool ret = false;
			{
                aniParams._Pos = faceAni.curFaceTrans._Position;
                aniParams._Rot = faceAni.curFaceTrans._Rotation;

                aniParams._Eye1Open = faceAni.curEye1Height / faceAni.Data._eye1_max_height;
                aniParams._Eye2Open = faceAni.curEye2Height / faceAni.Data._eye2_max_height;
                ret = true;
            }
            return ret;
        }

        void syncAniParams()
		{
            trans.position = _AniParams._Pos;
            trans.rotation = _AniParams._Rot;

            mat.SetFloat(_MatNameIDs._Eye1Open.ID, _AniParams._Eye1Open);
            mat.SetFloat(_MatNameIDs._Eye2Open.ID, _AniParams._Eye2Open);
        }

		private void Update()
		{
            syncBaseParams();

            if (_BindFaceAnimation)
			{
                _BindFaceAnimation._Update();
                if(face_to_furball_animation(_BindFaceAnimation, ref _AniParams))
				{
                    syncAniParams();
                }                
            }
		}

		private void Start()
		{
            _MatNameIDs = new MatNameIDs();
		}

	}
}
