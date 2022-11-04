using System;
using System.Collections.Generic;
using UnityEngine;

public class FaceAnimation : MonoBehaviour
{
    [Serializable]
    public class Trans
	{
        public Vector3    _Position;
        public Quaternion _Rotation;
	}

    public string      _JsonPath;
    public float       _TimeLength;
    public List<float> _Keys;


    public List<Trans>   _FaceTrans;
    public List<Vector2> _PupilUV;

    private FaceAniData _Data;

    [ContextMenu("LoadData")]
    void LoadData()
	{
        _Data = FaceAniData.loadFromFile(_JsonPath);

        //Fill Face Trans
        _FaceTrans = new List<Trans>();
        int frameCount = _Data._face_frames_pts.Count;

        for(int iFrame=0;iFrame<frameCount;iFrame++)
		{
            var facePts = _Data._face_frames_pts[iFrame];
            var nosePts = _Data._nose_frames_pts[iFrame];
            var eye1Pts = _Data._eye1_frames_pts[iFrame];
            var eye2Pts = _Data._eye2_frames_pts[iFrame];
            var pupil1Pt = _Data._pupil1_frames_pts[iFrame];
            var pupil2Pt = _Data._pupil2_frames_pts[iFrame];

            Vector3 face0Pt = facePts[0];
            Vector3 face_1Pt = facePts[facePts.Count - 1];
            Vector3 faceRight = face0Pt - face_1Pt;
            faceRight.Normalize();

            Vector3 face1Pt = facePts[1];
            Vector3 face_2Pt = facePts[facePts.Count - 2];

            Vector3 eye1InnerPt = eye1Pts[3];
            Vector3 eye2InnerPt = eye2Pts[0];

            Vector3 faceForward = ((eye1InnerPt + eye2InnerPt) - (face1Pt + face_2Pt)) * 0.5f;
            faceForward.Normalize();

            Vector3 faceUp = Vector3.Cross(faceForward, faceRight);

            Vector3 face4Pt = facePts[4];
            Vector3 face_5Pt = facePts[facePts.Count - 5];

            Vector3 nose_1Pt = nosePts[nosePts.Count - 1];
            Vector3 facePos = ((face4Pt + face_5Pt) * 0.5f + nose_1Pt) * 0.5f;

            //QuaternionW = ¡Ì(1 + M00 + M11 + M22) / 2
            //QuaternionX = (M21 - M12) / (QuaternionW * 4)
            //QuaternionY = (M02 - M20) / (QuaternionW * 4)
            //QuaternionZ = (M10 - M01) / (QuaternionW * 4)

            Trans faceTrans = new Trans();
            faceTrans._Rotation.w = Mathf.Pow(1.0f+faceRight.x + faceUp.y + faceForward.z, 0.5f);
            float fW4 = faceTrans._Rotation.w * 4.0f;
            faceTrans._Rotation.x = (faceUp.z - faceForward.y) / fW4;
            faceTrans._Rotation.y = (faceForward.x - faceRight.z) / fW4;
            faceTrans._Rotation.z = (faceRight.y - faceUp.x) / fW4;

            faceTrans._Position = facePos;

            _FaceTrans.Add(faceTrans);
        }
	}


    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
