using System;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

namespace FFExpression
{
    [CustomEditor(typeof(ExpressionBase))]
    public class ExpressionEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            if(GUILayout.Button("Start"))
            {
                ((ExpressionBase)target).StartExpression(null);
            }
        }
    }
}