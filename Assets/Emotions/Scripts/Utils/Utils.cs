using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Reflection;

namespace FFUtils
{
    public static class Maths
	{
		public static Vector3 sphericalToCartesian(Vector3 uvr, Vector3 center)
		{
			Vector3 pos;

			uvr.x =  Mathf.Clamp01(uvr.x);
			uvr.y =  Mathf.Clamp01(uvr.y);
			uvr.x *= Mathf.PI;
			uvr.y *= Mathf.PI;

			pos.x = Mathf.Sin(uvr.y) * Mathf.Cos(uvr.x);
			pos.z = Mathf.Sin(uvr.y) * Mathf.Sin(uvr.x);
			pos.y = Mathf.Cos(uvr.y);
			pos *= uvr.z;
			pos += center;
			return pos;
		}
	}

	public class Mat_NameID
	{
		private string _Name;
		private int _ID;

		public string Name
		{
			get
			{
				return _Name;
			}
		}

		public int ID
		{
			get
			{
				return _ID;
			}
			set
			{
				_ID = value;
			}
		}

		public Mat_NameID(string name)
		{
			_Name = name;
			_ID = Shader.PropertyToID(_Name);
		}
		
		public static void fillFields(object obj)
		{
			FieldInfo[] fieldInfos;

			Type t = obj.GetType();
			// Get the type and fields of FieldInfoClass.
			fieldInfos = t.GetFields(BindingFlags.Instance | BindingFlags.Public);

			// Display the field information of FieldInfoClass.
			for (int i = 0; i < fieldInfos.Length; i++)
			{
				var fieldInfo = fieldInfos[i];
				var fieldName = fieldInfo.Name;
				fieldInfo.SetValue(obj, new Mat_NameID(fieldName));
			}
		}
	}


}

