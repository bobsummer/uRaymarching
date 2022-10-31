using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

public class FaceAnimation
{
	public int width;
	public int height;

	public List<float> face;
	public List<float> eye1;
	public List<float> eye2;

	public List<int> faceShape;
	public List<int> eye1Shape;
	public List<int> eye2Shape;

	[NonSerialized]
	public List<List<Vector3>> face_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<List<Vector3>> eye1_frames_pts = new List<List<Vector3>>();
	[NonSerialized]
	public List<List<Vector3>> eye2_frames_pts = new List<List<Vector3>>();

	protected void syncData()
	{
		//face_frames_pts
		int pointSize = faceShape[1];
		int pointCount = faceShape[0];
		int frameCount = face.Count / (pointCount * pointSize);
		for(int iFrame=0;iFrame<frameCount;iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			for(int iPoint=0;iPoint<pointCount;iPoint++)
			{
				int idx = iFrame * iPoint * pointSize;
				Vector3 pt;
				pt.x = face[idx];
				pt.y = face[idx + 1];
				pt.z = face[idx + 2];
				points.Add(pt);
			}
			face_frames_pts.Add(points);
		}

		//eye1_frames_pts
		pointSize = eye1Shape[1];
		pointCount = eye1Shape[0];
		frameCount = eye1.Count / (pointCount * pointSize);
		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			for (int iPoint = 0; iPoint < pointCount; iPoint++)
			{
				int idx = iFrame * iPoint * pointSize;
				Vector3 pt;
				pt.x = eye1[idx];
				pt.y = eye1[idx + 1];
				pt.z = eye1[idx + 2];
				points.Add(pt);
			}
			eye1_frames_pts.Add(points);
		}

		//eye2_frames_pts
		pointSize = eye2Shape[1];
		pointCount = eye2Shape[0];
		frameCount = eye2.Count / (pointCount * pointSize);
		for (int iFrame = 0; iFrame < frameCount; iFrame++)
		{
			List<Vector3> points = new List<Vector3>();
			for (int iPoint = 0; iPoint < pointCount; iPoint++)
			{
				int idx = iFrame * iPoint * pointSize;
				Vector3 pt;
				pt.x = eye2[idx];
				pt.y = eye2[idx + 1];
				pt.z = eye2[idx + 2];
				points.Add(pt);
			}
			eye2_frames_pts.Add(points);
		}
	}

	public static FaceAnimation loadFromFile(string filePath)
	{
		FaceAnimation ret;

		var text_asset = AssetDatabase.LoadAssetAtPath<TextAsset>(filePath);
		ret = JsonUtility.FromJson<FaceAnimation>(text_asset.text);
		ret.syncData();

		return ret;
	}

	[MenuItem("Tools/loadTest")]
	public static void loadTest()
	{
		FaceAnimation a = loadFromFile("Assets/Emotions/Animations/R-C_frames.json");


	}
}
