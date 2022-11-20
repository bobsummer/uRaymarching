using UnityEngine;
using System.Collections.Generic;

namespace FFExpression
{
    [System.Serializable]
    public class AnimationData
    {
        public Animator _Animator = null;
        public string   _AnimationName = "";
        public float    _AnimationSpeedScale = 1.0f;
        public int      _EventIdx = -1;
    }

    public partial class ExpressionBase : MonoBehaviour
    {
        public int _GifStartIdx = 2;
        public int _GifFrameDelay = 16;
        public float _AnimationSpeed = 1;
        public int _UpdateDelayCount = 3;

		[SerializeField]
		public List<AnimationData> _StartAnimationDatas = new List<AnimationData>();
        [SerializeField]
        public List<AnimationData> _DelayedAnimationDatas = new List<AnimationData>();
        [SerializeField]
        public List<AnimationData> _EventAnimationDatas = new List<AnimationData>();

		public enum EyeToolsType
		{
			Mirror = 0,
			Syntropy,
			Unknown,
		}

		public EyeToolsType _EyeToolsType = EyeToolsType.Mirror;

        public Camera export_camera
        {
            get
            {
                Camera ret = null;
                ret = GetComponentInChildren<Camera>();
                return ret;
            }         
        }

        public SaveRTCameraEvent save_rt_evt
        {
            get
            {
                return export_camera.GetComponent<SaveRTCameraEvent>();
            }
        }     

        protected void setAnimatorTrigger(Animator animator,string triggerName,float speed_scale)
        {
            if(animator!=null)
            {
                animator.speed = _AnimationSpeed*speed_scale;
                animator.SetTrigger(triggerName);
            }
        }
    }
}
