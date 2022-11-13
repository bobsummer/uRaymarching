using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.Linq;

public class FaceAniData
{
	public int width;
	public int height;

	public List<float> face;
	public List<float> eye1;
	public List<float> eye2;
	public List<float> nose;
	public List<float> pupil_1;
	public List<float> pupil_2;

	public List<int> faceShape;
	public List<int> noseShape;
	public List<int> eye1Shape;
	public List<int> eye2Shape;

	[NonSerialized]
	public List<List<Vector3>> _face_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<List<Vector3>> _nose_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<List<Vector3>> _eye1_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<List<Vector3>> _eye2_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<Vector3> _pupil1_frames_pts = new List<Vector3>();
	[NonSerialized]
	public List<Vector3> _pupil2_frames_pts = new List<Vector3>();

	[NonSerialized]
	public List<float> _eye1_frame_heights = new List<float>();
	[NonSerialized]
	public float _eye1_max_height = 0.0f;
	[NonSerialized]
	public List<float> _eye2_frame_heights = new List<float>();
	[NonSerialized]
	public float _eye2_max_height = 0.0f;

	protected void syncData()
	{
		float fWidth = width;
		float fHeight = height;
		float fDepth = (fWidth + fHeight) * 0.5f;		

		//face_frames_pts
		int pointSize = faceShape[1];
		int pointCount = faceShape[0];
		int frameCount = face.Count / (pointCount * pointSize);
		for(int iFrame=0;iFrame<frameCount;iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			for(int iPoint=0;iPoint<pointCount;iPoint++)
			{
				int idx = iFrame * pointCount * pointSize + iPoint * pointSize;
				Vector3 pt;
				pt.x = face[idx]/fWidth;
				pt.y = face[idx + 1]/fHeight;

				pt.x -= 0.5f;
				pt.x *= -1.0f;
				pt.y -= 0.5f;
				pt.y *= -1.0f;

				pt.z = face[idx + 2]/fDepth;
				points.Add(pt);
			}
			_face_frames_pts.Add(points);
		}
		_face_frames_pts.Add(_face_frames_pts[0]);

		//nose_frames_pts
		pointSize = noseShape[1];
		pointCount = noseShape[0];
		int tmpframeCount = nose.Count / (pointCount * pointSize);
		if (tmpframeCount != frameCount)
		{
			Debug.LogErrorFormat("FrameCount {0} != {1}", tmpframeCount, frameCount);
		}

		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			for (int iPoint = 0; iPoint < pointCount; iPoint++)
			{
				int idx = iFrame * pointCount * pointSize + iPoint * pointSize;
				Vector3 pt;
				pt.x = nose[idx] / fWidth;
				pt.y = nose[idx + 1] / fHeight;

				pt.x -= 0.5f;
				pt.x *= -1.0f;
				pt.y -= 0.5f;
				pt.y *= -1.0f;

				pt.z = nose[idx + 2] / fDepth;
				points.Add(pt);
			}
			_nose_frames_pts.Add(points);
		}
		_nose_frames_pts.Add(_nose_frames_pts[0]);

		//eye1_frames_pts
		pointSize = eye1Shape[1];
		pointCount = eye1Shape[0];
		tmpframeCount = eye1.Count / (pointCount * pointSize);
		if(tmpframeCount!=frameCount)
		{
			Debug.LogErrorFormat("FrameCount {0} != {1}",tmpframeCount,frameCount);
		}

		float pointRatio = 1.0f / pointCount;

		List<float> eye1AvgDepth = new List<float>();

		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			float avgDepth = 0.0f;
			for (int iPoint = 0; iPoint < pointCount; iPoint++)
			{
				int idx = iFrame * pointCount * pointSize + iPoint * pointSize;
				Vector3 pt;
				pt.x = eye1[idx]/fWidth;
				pt.y = eye1[idx + 1] / fHeight;

				pt.x -= 0.5f;
				pt.x *= -1.0f;				
				pt.y -= 0.5f;
				pt.y *= -1.0f;

				pt.z = eye1[idx + 2]/fDepth;
				points.Add(pt);
				avgDepth += pt.z * pointRatio;
			}
			_eye1_frames_pts.Add(points);

			Vector3 uPoint = (points[1] + points[2]) * 0.5f;
			Vector3 dPoint = (points[4] + points[5]) * 0.5f;
			_eye1_frame_heights.Add((uPoint - dPoint).magnitude);

			eye1AvgDepth.Add(avgDepth);
		}

		_eye1_max_height = _eye1_frame_heights.AsQueryable().Max();
		_eye1_frames_pts.Add(_eye1_frames_pts[0]);

		//eye2_frames_pts
		pointSize = eye2Shape[1];
		pointCount = eye2Shape[0];

		pointRatio = 1.0f / pointCount;

		tmpframeCount = eye2.Count / (pointCount * pointSize);
		if (tmpframeCount != frameCount)
		{
			Debug.LogErrorFormat("FrameCount {0} != {1}", tmpframeCount, frameCount);
		}
		//frameRatio = 1.0f / frameCount;
		List<float> eye2AvgDepth = new List<float>();

		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			float avgDepth = 0.0f;
			for (int iPoint = 0; iPoint < pointCount; iPoint++)
			{
				int idx = iFrame * pointCount * pointSize + iPoint * pointSize;
				Vector3 pt;

				pt.x = eye2[idx]/fWidth;
				pt.y = eye2[idx + 1]/fHeight;

				pt.x -= 0.5f;
				pt.x *= -1.0f;
				pt.y -= 0.5f;
				pt.y *= -1.0f;

				pt.z = eye2[idx + 2]/fDepth;
				points.Add(pt);
				avgDepth += pt.z * pointRatio;
			}
			_eye2_frames_pts.Add(points);

			Vector3 uPoint = (points[1] + points[2]) * 0.5f;
			Vector3 dPoint = (points[4] + points[5]) * 0.5f;
			_eye2_frame_heights.Add((uPoint - dPoint).magnitude);

			eye2AvgDepth.Add(avgDepth);
		}

		_eye2_max_height = _eye2_frame_heights.AsQueryable().Max();
		_eye2_frames_pts.Add(_eye2_frames_pts[0]);

		//pupil1_frames_pt
		pointSize = 2;
		tmpframeCount = pupil_1.Count/pointSize;
		if (tmpframeCount != frameCount)
		{
			Debug.LogErrorFormat("FrameCount {0} != {1}", tmpframeCount, frameCount);
		}
		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			Vector3 pt;
			int idx = iFrame * 2;
			pt.x = pupil_1[idx]/fWidth;
			pt.y = pupil_1[idx + 1]/fHeight;

			pt.x -= 0.5f;
			pt.x *= -1.0f;
			pt.y -= 0.5f;
			pt.y *= -1.0f;

			pt.z = eye1AvgDepth[iFrame];
			_pupil1_frames_pts.Add(pt);
		}
		_pupil1_frames_pts.Add(_pupil1_frames_pts[0]);

		//pupil2_frames_pt
		tmpframeCount = pupil_2.Count/pointSize;
		if (tmpframeCount != frameCount)
		{
			Debug.LogErrorFormat("FrameCount {0} != {1}", tmpframeCount, frameCount);
		}
		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			Vector3 pt;
			int idx = iFrame * 2;
			pt.x = pupil_2[idx] / fWidth;
			pt.y = pupil_2[idx + 1] / fHeight;

			pt.x -= 0.5f;
			pt.x *= -1.0f;
			pt.y -= 0.5f;
			pt.y *= -1.0f;

			pt.z = eye2AvgDepth[iFrame];
			_pupil2_frames_pts.Add(pt);
		}
		_pupil2_frames_pts.Add(_pupil2_frames_pts[0]);
	}

	public static FaceAniData loadFromFile(string filePath)
	{
		FaceAniData ret;

		var text_asset = AssetDatabase.LoadAssetAtPath<TextAsset>(filePath);
		ret = JsonUtility.FromJson<FaceAniData>(text_asset.text);
		ret.syncData();

		return ret;
	}

	[MenuItem("Tools/loadTest")]
	public static void loadTest()
	{
		FaceAniData fa = loadFromFile("Assets/Emotions/Animations/R-C_frames.json");

	}
}