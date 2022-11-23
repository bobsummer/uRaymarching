using System;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

using FurBall;

namespace FFExpression
{
    [CustomEditor(typeof(FurBallParams))]
    public class FurBallParamsEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            FurBallParams fbParams = target as FurBallParams;
            if(GUILayout.Button("OpenEditorUpdate"))
            {
                fbParams.openEditorUpdate();
            }
            if (GUILayout.Button("CloseEditorUpdate"))
            {
                fbParams.closeEditorUpdate();
            }
            if (GUILayout.Button("Tick"))
			{
                fbParams.Tick();
			}
        }
    }
}