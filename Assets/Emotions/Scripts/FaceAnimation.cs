using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class FaceAnimation : MonoBehaviour
{
    public enum State
    {
        Stop = 0,
        Pause,
        Play,
    }
    protected State _State = State.Stop;

    [Serializable]
    public class Trans
	{
        public Vector3    _Position;
        public Quaternion _Rotation;
	}

    public GameObject _BindObj = null;

    private bool        _Loop = true;
    public string      _JsonPath;
    public float       _TimeLength;
    public float       _TimeLine;
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
        _Keys = new List<float>();

        int frameCount = _Data._face_frames_pts.Count;
        float deltaTime = 1.0f/(frameCount-1);
        float fTime = 0.0f;

        for(int iFrame=0;iFrame<frameCount;iFrame++)
		{
            _Keys.Add(fTime);
            fTime += deltaTime;

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

            //inline void CalculateRotation(Quaternion&q ) const 
            //{
            //    float trace = a[0][0] + a[1][1] + a[2][2];
            //    if (trace > 0)
            //    {// I changed M_EPSILON to 0
            //        float s = 0.5f / sqrtf(trace + 1.0f);
            //        q.w = 0.25f / s;
            //        q.x = (a[2][1] - a[1][2]) * s;
            //        q.y = (a[0][2] - a[2][0]) * s;
            //        q.z = (a[1][0] - a[0][1]) * s;
            //    }
            //    else
            //    {
            //        if (a[0][0] > a[1][1] && a[0][0] > a[2][2])
            //        {
            //            float s = 2.0f * sqrtf(1.0f + a[0][0] - a[1][1] - a[2][2]);
            //            q.w = (a[2][1] - a[1][2]) / s;
            //            q.x = 0.25f * s;
            //            q.y = (a[0][1] + a[1][0]) / s;
            //            q.z = (a[0][2] + a[2][0]) / s;
            //        }
            //        else if (a[1][1] > a[2][2])
            //        {
            //            float s = 2.0f * sqrtf(1.0f + a[1][1] - a[0][0] - a[2][2]);
            //            q.w = (a[0][2] - a[2][0]) / s;
            //            q.x = (a[0][1] + a[1][0]) / s;
            //            q.y = 0.25f * s;
            //            q.z = (a[1][2] + a[2][1]) / s;
            //        }
            //        else
            //        {
            //            float s = 2.0f * sqrtf(1.0f + a[2][2] - a[0][0] - a[1][1]);
            //            q.w = (a[1][0] - a[0][1]) / s;
            //            q.x = (a[0][2] + a[2][0]) / s;
            //            q.y = (a[1][2] + a[2][1]) / s;
            //            q.z = 0.25f * s;
            //        }
            //    }
            //}

            Trans faceTrans = new Trans();

            float trace = faceRight.x + faceUp.y + faceForward.z;

            if(trace>0.0)
            {
                float s = 0.5f / Mathf.Pow(trace,0.5f);
                faceTrans._Rotation.w = 0.25f/s;
                faceTrans._Rotation.x = (faceUp.z-faceForward.y) * s;
                faceTrans._Rotation.y = (faceForward.x-faceRight.z) * s;
                faceTrans._Rotation.z = (faceRight.y - faceUp.x) * s;
            }
            else
            {
                if(faceRight.x>faceUp.y && faceRight.x>faceForward.z)
                {
                    float s = 2.0f * Mathf.Pow(1.0f + faceRight.x - faceUp.y - faceForward.z,0.5f);
                    faceTrans._Rotation.w = (faceUp.z-faceForward.y) / s;
                    faceTrans._Rotation.x = 0.25f * s;
                    faceTrans._Rotation.y = (faceUp.x + faceRight.y) * s;
                    faceTrans._Rotation.z = (faceForward.x - faceRight.z) * s;
                }
                else if(faceUp.y > faceForward.z)
                {
                    float s = 2.0f * Mathf.Pow(1.0f + faceUp.y - faceRight.x - faceForward.z,0.5f);
                    faceTrans._Rotation.w = (faceForward.x-faceRight.z) / s;
                    faceTrans._Rotation.x = (faceUp.x + faceRight.y) / s;
                    faceTrans._Rotation.y = 0.25f * s;
                    faceTrans._Rotation.z = (faceForward.y + faceUp.z) / s;
                }
                else
                {
                    float s = 2.0f * Mathf.Pow(1.0f + faceForward.z - faceRight.x - faceUp.y,0.5f);
                    faceTrans._Rotation.w = (faceRight.y - faceUp.x) / s;
                    faceTrans._Rotation.x = (faceForward.x + faceRight.z) / s;
                    faceTrans._Rotation.y = (faceForward.y + faceUp.z) / s;
                    faceTrans._Rotation.z = 0.25f * s;
                }
            }
            faceTrans._Rotation.Normalize();
            faceTrans._Position = facePos;
            _FaceTrans.Add(faceTrans);
        }
	}

    int selecetKey(float percent,out float ratio_between_keys)
	{
        int preKeyIdx = 0;
        bool bingo = false;
        ratio_between_keys = 0.0f;
        for (;preKeyIdx<_Keys.Count-1;preKeyIdx++)
		{
            float preKey = _Keys[preKeyIdx];
            float postKey = _Keys[preKeyIdx + 1];
            if(percent>=preKey && percent<=postKey)
			{
                ratio_between_keys = (percent - preKey) / (postKey - preKey);
                bingo = true;
                break;
			}
		}
        if(!bingo)
		{
            preKeyIdx = -1;
		}
        return preKeyIdx;
	}

    [ContextMenu("Play")]
    void Play()
    {
        if(_State==State.Stop)
        {
            _TimeLine = 0.0f;
            _State = State.Play;
        }
        else if(_State==State.Pause)
        {
            _State = State.Play;
        }
    }

    void Pause()
    {
        if(_State==State.Play)
        {
            _State = State.Pause;
        }

    }

    void Stop()
    {

    }

    List<Vector3> lerp_pts(List<Vector3> prePts,List<Vector3> postPts,float ratio)
	{
        List<Vector3> retPts = new List<Vector3>();
        int count = Mathf.Min(prePts.Count, postPts.Count);
        for(int i=0;i<count;i++)
		{
            var prePt = prePts[i];
            var postPt = postPts[i];
            var pt = Vector3.Lerp(prePt, postPt, ratio);
            retPts.Add(pt);
		}
        return retPts;
    }

	private void Start()
	{
        LoadData();
	}

    public void _Update()
    {
        if(_State==State.Play)
		{
            float percent = _TimeLine / _TimeLength;

            if(percent>1.0f)
			{
                if(_Loop)
				{
                    percent -= Mathf.Floor(percent);
				}
                else
				{
                    percent = 1.0f;
                    _State = State.Stop;
				}
			}

            float ratio_between_keys;

            int preKeyIdx = selecetKey(percent,out ratio_between_keys);

            Transform faceTrans = null;

            for(int iChild=0;iChild<transform.childCount;iChild++)
			{
                Transform transChild = transform.GetChild(iChild);
                List<List<Vector3>> frame_pts = null;
                List<Vector3> frame_pupil_pts = null;
                switch (transChild.name)
                {
                    case "Face":
                        {
                            frame_pts = _Data._face_frames_pts;
                            break;
                        }
                    case "Eye1":
                        {
                            frame_pts = _Data._eye1_frames_pts;
                            break;
                        }
                    case "Eye2":
                        {
                            frame_pts = _Data._eye2_frames_pts;
                            break;
                        }
                    case "Nose":
                        {
                            frame_pts = _Data._nose_frames_pts;
                            break;
                        }
                    case "FaceTrans":
						{
                            faceTrans = transChild;
                            break;
						}
                    case "Pupil1":
						{
                            frame_pupil_pts = _Data._pupil1_frames_pts;
                            break;
						}
                    case "Pupil2":
						{
                            frame_pupil_pts = _Data._pupil2_frames_pts;
                            break;
						}
                    default:
                        {
                            break;
                        }
                }
                if(frame_pts!=null)
				{
                    LineRenderer line_rdr = transChild.GetComponent<LineRenderer>();
                    var prePts = frame_pts[preKeyIdx];
                    int postKeyIdx = preKeyIdx + 1;
                    if(postKeyIdx >= frame_pts.Count)
					{
                        postKeyIdx = 0;
					}
                    var postPts = frame_pts[postKeyIdx];
                    var pts = lerp_pts(prePts, postPts, ratio_between_keys);
                    line_rdr.positionCount = pts.Count;
                    line_rdr.SetPositions(pts.ToArray());
                }
                else if(frame_pupil_pts!=null)
				{
                    var prePt = frame_pupil_pts[preKeyIdx];
                    int postKeyIdx = preKeyIdx + 1;
                    if (postKeyIdx >= frame_pupil_pts.Count)
                    {
                        postKeyIdx = 0;
                    }
                    var postPt = frame_pupil_pts[postKeyIdx];
                    var pt = Vector3.Lerp(prePt, postPt, ratio_between_keys);
                    transChild.position = pt;
                }
			}

            if(faceTrans!=null)
			{
                Trans preTrans = _FaceTrans[preKeyIdx];
                Trans postTrans = _FaceTrans[Mathf.Min(preKeyIdx + 1, _FaceTrans.Count - 1)];

                Vector3 lerpPt = Vector3.Lerp(preTrans._Position, postTrans._Position, ratio_between_keys);
                Quaternion lerpQuat = Quaternion.Lerp(preTrans._Rotation, postTrans._Rotation, ratio_between_keys);
                faceTrans.position = lerpPt;
                faceTrans.rotation = lerpQuat;

                if(_BindObj!=null)
				{
                    _BindObj.transform.position = faceTrans.position;
                    _BindObj.transform.rotation = faceTrans.rotation;
				}
			}

            _TimeLine += Time.deltaTime;
		}
        
    }
}
