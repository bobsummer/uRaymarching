using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Gif.Components;
using System.Drawing;
using UnityEditor;
using FurBall;
using UnityEngine.Rendering;
using System;

namespace FFExpression
{
    public class ExpressionExporter : MonoBehaviour
    {
        public int _Width = 240;
        public int _Height = 240;
        public string _OutputFolderName = "D:/Expressions/";

        public string _AnimClipsFolder = "Assets/FaceAnims/";

        public RenderTexture _RenderTexture = null;
        public bool _useRT = true;
        private static ExpressionExporter _Instance = null;

        private int _FrameCounter = 0;

        [SerializeField]
        private List<string> _ExpressionPaths = new List<string>();

        [SerializeField]
        private List<string> _ExpressionNames = new List<string>();

        public Color32 _KeyColor = new Color32(180, 0, 180,255);

        private List<AnimationClip> _AnimClips = new List<AnimationClip>();
        private int _curAnimClipIdx = 0;

        public UnityEditor.Animations.AnimatorController _animCtrl;

        public static ExpressionExporter instance
        {
            get
            {
                return _Instance;
            }
        }

        Animator _animator;
        Animator animator
        {
            get
            {
                if (_animator == null)
                {
                    _animator = GetComponent<Animator>();
                }
                return _animator;
            }
        }

        FurBallParams _furballParams;
        FurBallParams furballParams
		{
            get
			{
                if(_furballParams==null)
				{
                    _furballParams = GetComponent<FurBallParams>();
				}
                return _furballParams;
			}
		}

        Camera outputCamera
		{
            get
			{
                return Camera.main;
			}
		}

		void Start()
        {
            _Instance = this;
        }

        public void Clear()
		{
            _AnimClips.Clear();
        }

        public void ForceEndExport()
		{
            RenderPipelineManager.endCameraRendering -= OnEndCameraRendering;
            furballParams.closeEditorUpdate();
        }
        
        public void Export()
        {
            _Instance = this;
            if(Directory.Exists(_OutputFolderName))
            {
                Directory.Delete(_OutputFolderName,true);
            }
            Directory.CreateDirectory(_OutputFolderName);
            if(_useRT)
            {
                if(_RenderTexture==null)
                {
                    _RenderTexture = new RenderTexture(_Width,_Height,24,RenderTextureFormat.ARGB32);
                }
            }

            _AnimClips.Clear();
            _ExpressionNames.Clear();
            _ExpressionPaths.Clear();

            if (Directory.Exists(_AnimClipsFolder))
            {
                DirectoryInfo direction = new DirectoryInfo(_AnimClipsFolder);
                FileInfo[] files = direction.GetFiles("*", SearchOption.AllDirectories);
                for (int i = 0; i < files.Length; i++)
                {
                    if (files[i].Name.EndsWith(".meta"))
                    {
                        continue;
                    }
                    string animPath = _AnimClipsFolder + files[i].Name;
                    var animClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(animPath);
                    if(animClip!=null)
					{
                        _AnimClips.Add(animClip);
					}
                }
            }

            if(_AnimClips.Count>0)
			{
                //RenderPipelineManager.endContextRendering += OnEndContextRendering;
                //RenderPipelineManager.endCameraRendering += OnEndCameraRendering;

                outputCamera.targetTexture = _RenderTexture;
                
                //EditorApplication.isPlaying = true;
                furballParams.openEditorUpdate();

                _curAnimClipIdx = -1;
                tickAnimClip();
            }
        }


        public void tickAnimClip()
		{
            _curAnimClipIdx++;
            if(_curAnimClipIdx<_AnimClips.Count)
			{
                var curAnimClip = _AnimClips[_curAnimClipIdx];

                _FrameCounter = 0;

                string output_path = _OutputFolderName + curAnimClip.name;
                Directory.CreateDirectory(output_path);

                _ExpressionPaths.Add(output_path);
                _ExpressionNames.Add(curAnimClip.name);

                foreach(var state in _animCtrl.layers[0].stateMachine.states)
				{
                    if(state.state.name == "anim")
					{
                        state.state.motion = curAnimClip;
					}
				}
                animator.Play("anim");

                //Debug.LogFormat("Play anim {0}", curAnimClip.name);
            }
            else
			{
                onAllExpressionOver();
			}
            
		}

        void OnEndContextRendering(ScriptableRenderContext context, List<Camera> cameras)
        {
            // Put the code that you want to execute at the end of RenderPipeline.Render here
            if(cameras.Count==1)
			{
                RenderTexture rt = cameras[0].targetTexture;
                if (rt != null)
                {
                    SaveRenderTextureToPng(rt);
                }
            }
        }

        void OnEndCameraRendering(ScriptableRenderContext context, Camera camera)
        {
            saveRT();
        }

        public void saveRT()
		{
            RenderTexture rt = outputCamera.targetTexture;
            if (rt != null)
            {
                SaveRenderTextureToPng(rt);
            }
        }
      
        private void onAllExpressionOver()
        {
            _curAnimClipIdx = -1;
            //RenderPipelineManager.endContextRendering -= OnEndContextRendering;
            //RenderPipelineManager.endCameraRendering -= OnEndCameraRendering;

            outputCamera.targetTexture = null;

            //EditorApplication.isPlaying = false;
            furballParams.closeEditorUpdate();

            encode_gif();
		}

        public void encode_gif()
		{
            for (int i = 0; i < _ExpressionPaths.Count; i++)
            {
                var path = _ExpressionPaths[i];
                var expression_name = _ExpressionNames[i];
                string[] pngfiles = Directory.GetFileSystemEntries(path, "*.png");
                string gif_file = path + "/" + expression_name + ".gif";

                AnimatedGifEncoder gif_encoder = new AnimatedGifEncoder();
                gif_encoder.Start(gif_file);
                //gif_encoder.SetDelay(expression._GifFrameDelay);
                gif_encoder.SetRepeat(0);
                System.Drawing.Color key_color = System.Drawing.Color.FromArgb(_KeyColor.r, _KeyColor.g, _KeyColor.b);
                //gif_encoder.SetTransparent(key_color);
                for (int iPNG = 0; iPNG < pngfiles.Length; iPNG++)
                {
                    var png_file = pngfiles[iPNG];
                    //Debug.Log(png_file);
                    gif_encoder.AddFrame(Image.FromFile(png_file));
                }
                gif_encoder.Finish();
            }
        }

        public Texture2D SaveRenderTextureToPng(RenderTexture rt)
        {
            if(_curAnimClipIdx>=0 && _curAnimClipIdx<_AnimClips.Count)
			{
                int width = rt.width;
                int height = rt.height;
                Texture2D tex2d = new Texture2D(width, height, TextureFormat.ARGB32, false);
                RenderTexture.active = rt;
                tex2d.ReadPixels(new Rect(0, 0, width, height), 0, 0);
                tex2d.Apply();

                byte[] b = tex2d.EncodeToPNG();
                string curExpressionName = _ExpressionNames[_curAnimClipIdx];
                string output_path = _OutputFolderName + curExpressionName;
                string file_name = string.Format("{0}", _FrameCounter++);
                file_name = file_name.PadLeft(4, '0');
                FileStream file = File.Open(output_path + "/" + file_name + ".png", FileMode.Create);
                BinaryWriter writer = new BinaryWriter(file);
                writer.Write(b);
                file.Close();

                //Debug.LogFormat("Output png {0}", file_name);

                return tex2d;
            }
            return null;
        }
    }
}