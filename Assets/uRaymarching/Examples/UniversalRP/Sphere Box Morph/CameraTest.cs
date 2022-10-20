using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraTest : MonoBehaviour
{
    // Start is called before the first frame update

    // Update is called once per frame
    void Update()
    {
        Camera cam = GetComponent<Camera>();

        Matrix4x4 projMatrix = cam.projectionMatrix;
        Matrix4x4 invProjMatrix = projMatrix.inverse;

        Matrix4x4 wcMatrix = cam.worldToCameraMatrix;
        Matrix4x4 cwMatrix = cam.cameraToWorldMatrix;

        Vector4 worldPoint1 = new Vector4(3.31f, 5.12f, 6.43f,1.0f);

        Vector4 viewPoint1 = wcMatrix * worldPoint1;
        Vector4 projPoint = projMatrix * viewPoint1;
        Vector4 viewPoint2 = invProjMatrix * projPoint;
        Vector4 worldPoint2 = cwMatrix * viewPoint2;

        int n = 0;
        n++;
    }
}
