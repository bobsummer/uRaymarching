using System;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

namespace FFExpression
{
    [CustomEditor(typeof(ExpressionExporter))]
    public class ExporterEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            ExpressionExporter exporter = target as ExpressionExporter;
            if(GUILayout.Button("Export"))
            {
                exporter.Export();
            }
            if (GUILayout.Button("ForceEndExport"))
            {
                exporter.ForceEndExport();
            }
            if (GUILayout.Button("EncodeGif"))
			{
                exporter.encode_gif();
			}
        }
    }
}