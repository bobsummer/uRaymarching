using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace FFExpression
{
    public class SaveRTCameraEvent : MonoBehaviour
    {
        private Camera _Camera = null;
        //[ExecuteInEditMode]
        private void OnPostRender() 
        {
            if(_Camera==null)
            {
                _Camera = GetComponent<Camera>();
            }
            RenderTexture rt = _Camera.targetTexture;
            if(rt!=null)
            {
                ExpressionExporter.instance.SaveRenderTextureToPng(rt);
            }
        }

		private void Update()
		{
			
		}
	}
}