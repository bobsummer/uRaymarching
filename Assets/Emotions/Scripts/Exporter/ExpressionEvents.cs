using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

namespace FFExpression
{
    public partial class ExpressionBase : MonoBehaviour
    {
        public delegate void VoidExpressionDelegate(ExpressionBase expression);

		public virtual void StartExpression(ExpressionBase lastExpression)
		{
			OnExpressionStart();
			if (_StartAnimationDatas != null && _StartAnimationDatas.Count > 0)
			{
				foreach (var animData in _StartAnimationDatas)
				{
					setAnimatorTrigger(animData._Animator, animData._AnimationName, animData._AnimationSpeedScale);
				}
			}
		}


		public VoidExpressionDelegate _ExpressionStartDelegate;
        public virtual void OnExpressionStart()
        {
            _FrameCount = _UpdateDelayCount;
            if(_ExpressionStartDelegate!=null)
            {
                _ExpressionStartDelegate(this);
            }
        }

        private int _FrameCount = 0;
        protected virtual void Update()
        {
            if(_FrameCount>0)
            {
                _FrameCount--;
                if(_FrameCount==0)
                {
                    OnDelayedFrame();
                }
            }
            onUpdate();
        }

		private void Start()
		{
			float max_time = 0;
			AnimationClip max_time_clip = null;

			if (_DelayedAnimationDatas != null && _DelayedAnimationDatas.Count > 0)
			{
				foreach (var animData in _DelayedAnimationDatas)
				{
					foreach (var anim_clip in animData._Animator.runtimeAnimatorController.animationClips)
					{
						if (anim_clip.name == animData._AnimationName)
						{
							float time_len = anim_clip.length;
							if (time_len > max_time)
							{
								max_time = time_len;
								max_time_clip = anim_clip;
							}
						}
					}
				}
			}

			if (_StartAnimationDatas != null && _StartAnimationDatas.Count > 0)
			{
				foreach(var animData in _StartAnimationDatas)
				{
					foreach(var anim_clip in animData._Animator.runtimeAnimatorController.animationClips)
					{
						if(anim_clip.name == animData._AnimationName)
						{
							float time_len = anim_clip.length;
							if(time_len>max_time)
							{
								max_time = time_len;
								max_time_clip = anim_clip;
							}
						}
					}
				}
			}

			//add over event
			if (max_time_clip != null)
			{
				var new_anim_event = new AnimationEvent();
				new_anim_event.time = max_time;
				new_anim_event.functionName = "into_center";
				new_anim_event.intParameter = 0;
				max_time_clip.AddEvent(new_anim_event);
			}

			//int max_event_idx = 0;

			//EventsCenter evt_center = null;
			//Utils.IterateGameObject(gameObject, (game_obj, depth_level) =>
			//{
			//	evt_center = game_obj.GetComponent<EventsCenter>();
			//	if (evt_center != null)
			//	{
			//		return true;
			//	}
			//	else
			//	{
			//		return false;
			//	}
			//});

			//if (evt_center != null)
			//{
			//	if (_EventAnimationDatas != null && _EventAnimationDatas.Count > 0)
			//	{
			//		//find event center
			//		foreach (var anim_data in _EventAnimationDatas)
			//		{
			//			if (anim_data._EventIdx > max_event_idx)
			//			{
			//				max_event_idx = anim_data._EventIdx;
			//			}
			//		}
			//	}
			//	evt_center._Events = new UnityEventInt[max_event_idx + 1];
			//	for (int i_evt = 0; i_evt <= max_event_idx; i_evt++)
			//	{
			//		var new_unity_evt = new UnityEventInt();
			//		new_unity_evt.AddListener(onAnimationEvent);
			//		evt_center._Events[i_evt] = new_unity_evt;
			//	}
			//}
		}

		private void onAnimationEvent(int iEvt)
        {
			if(iEvt==0)
			{
				OnExpressionOver();
			}
			else
			{
				foreach (var evt_anim_data in _EventAnimationDatas)
				{
					if (evt_anim_data._EventIdx == iEvt)
					{
						setAnimatorTrigger(evt_anim_data._Animator, evt_anim_data._AnimationName, evt_anim_data._AnimationSpeedScale);
					}
				}
			}
		}

        protected virtual void onUpdate()
        { 

        }

        public VoidExpressionDelegate _ExpressionDelayFrameDelegate;
        protected virtual void OnDelayedFrame()
        {
            if(_ExpressionDelayFrameDelegate!=null)
            {
                _ExpressionDelayFrameDelegate(this);
            }
            if(_DelayedAnimationDatas!=null && _DelayedAnimationDatas.Count>0)
            {
                foreach (var animData in _DelayedAnimationDatas)
                {
                    setAnimatorTrigger(animData._Animator,animData._AnimationName,animData._AnimationSpeedScale);
                }
            }
			if (save_rt_evt != null)
			{
				save_rt_evt.enabled = true;
			}
		}        

        public VoidExpressionDelegate _ExpressionOverDelegate;
        public virtual void OnExpressionOver()
        {
            if(_ExpressionOverDelegate!=null)
            {
                _ExpressionOverDelegate(this);
            }
        }
    }
}
