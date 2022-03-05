//using BalsaCore;
//using BalsaCore.FX;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEditor;
using Modules;
//using CfgFields;
//using FSControl;
//using Construction;

namespace CloverTech
{
    public static class VectExt
    {
        public static Vector2 XZ(this Vector3 vect)
        {
            return new Vector2(vect.x, vect.z);
        }
    }

    public class HUDController : PartModule
    {

        class HoloShaderProperties
        {
            private readonly Renderer _renderer;
            private MaterialPropertyBlock _mpb;

            private static readonly int _centreTexIdx = Shader.PropertyToID("_CentreTex");
            private static readonly int _pitchTexIdx = Shader.PropertyToID("_PitchTex");
            private static readonly int _rollTexIdx = Shader.PropertyToID("_RollTex");
            private static readonly int _yawTexIdx = Shader.PropertyToID("_YawTex");
            private static readonly int _colourIdx = Shader.PropertyToID("_Colour");
            private static readonly int _alphaClipIdx = Shader.PropertyToID("_AlphaClip");
            private static readonly int _rollIdx = Shader.PropertyToID("_Roll");
            private static readonly int _pitchIdx = Shader.PropertyToID("_Pitch");
            private static readonly int _yawIdx = Shader.PropertyToID("_Yaw");
            private static readonly int _pitchRollYawIdx = Shader.PropertyToID("_PitchRollYaw");
            private static readonly int _velocityVectorIdx = Shader.PropertyToID("_VelocityVector");

            public HoloShaderProperties(Renderer renderer)
            {
                _renderer = renderer;
            }

            public MaterialPropertyBlock mpb
            {
                get
                {
                    if (_mpb == null)
                    {
                        _mpb = new MaterialPropertyBlock();
                        _renderer.GetPropertyBlock(_mpb,0);
                    }
                    return _mpb;
                }
            }

            public float Pitch
            {
                get { return mpb.GetFloat(_pitchIdx); }
                set { mpb.SetFloat(_pitchIdx, value); }
            }
            public float Roll
            {
                get { return mpb.GetFloat(_rollIdx); }
                set { mpb.SetFloat(_rollIdx, value); }
            }
            public float Yaw
            {
                get { return mpb.GetFloat(_yawIdx); }
                set { mpb.SetFloat(_yawIdx, value); }
            }

            public Vector4 PitchRollYaw
            {
                get { return mpb.GetVector(_pitchRollYawIdx); }
                set { mpb.SetVector(_pitchRollYawIdx, value); }
            }
            public Vector4 VelocityVector
            {
                get { return mpb.GetVector(_velocityVectorIdx); }
                set { mpb.SetVector(_velocityVectorIdx, value); }
            }

            public Texture CentreTex
            {
                get { return mpb.GetTexture(_centreTexIdx); }
                set { mpb.SetTexture(_centreTexIdx, value); }
            }
            public Texture PitchTex
            {
                get { return mpb.GetTexture(_pitchTexIdx); }
                set { mpb.SetTexture(_pitchTexIdx, value); }
            }
            public Texture RollTex
            {
                get { return mpb.GetTexture(_rollTexIdx); }
                set { mpb.SetTexture(_rollTexIdx, value); }
            }
            public Texture YawTex
            {
                get { return mpb.GetTexture(_yawTexIdx); }
                set { mpb.SetTexture(_yawTexIdx, value); }
            }

            public void ApplyBlock()
            {
                _renderer.SetPropertyBlock(mpb,0);
            }


        }

        HoloShaderProperties hsp;
        public Renderer rend;

        private void DoInitHsp()
        {
            rend = transform.Find("model")
                                      .Find("meshes")
                                      .Find("Glass new")
                                      .GetComponent<Renderer>();
            hsp = new HoloShaderProperties(rend);
        }

        public void OnValidate()
        {
            DoInitHsp();
        }

        public void OnEnable()
        {
            DoInitHsp();
        }
        public float apitch;
        public float aroll;
        public float ayaw;

        public float pitch;
        public float roll;
        public float yaw;

        public Vector3 velVec;
        public void Update()
        {

        }

        public void FixedUpdate()
        {
            Vector3 up = transform.TransformDirection(new Vector3(0, 1, 0));
            Vector3 front = transform.TransformDirection(new Vector3(0, 0, 1));
            pitch = Mathf.Atan2(front.y, Mathf.Sign(up.y) * front.XZ().magnitude);
            if (pitch > Mathf.PI / 2)
            {
                pitch = Mathf.PI - pitch;
            }
            else if (pitch < -Mathf.PI / 2)
            {
                pitch = -Mathf.PI - pitch;
            }

            Vector3 right = transform.TransformDirection(new Vector3(-1, 0, 0));
            Vector3 PitchPlaneNorm = Vector3.Cross(front, new Vector3(0, 1, 0)).normalized;
            Vector3 SupportAxis = Vector3.Cross(front, PitchPlaneNorm);
            Vector3 transFormedRight = new Vector3(Vector3.Dot(front, right),
                                                   Vector3.Dot(PitchPlaneNorm, right),
                                                   Vector3.Dot(SupportAxis, right));

            roll = -Mathf.Atan2(Mathf.Sign(Vector3.Dot(up, PitchPlaneNorm)) * transFormedRight.XZ().magnitude,
                                transFormedRight.y);
            yaw = Mathf.Atan2(front.x, front.z);
            hsp.PitchRollYaw = new Vector3(pitch, roll, yaw);
            apitch = pitch;
            aroll = roll;
            ayaw = yaw;
            if (Rb == null)
            {
                hsp.VelocityVector = new Vector4(0, 0, 0, 0);
                return;
            }
            Vector3 vel = Rb.velocity.normalized;
            pitch = Mathf.Atan2(vel.y, Mathf.Sign(up.y) * vel.XZ().magnitude);
            if (pitch > Mathf.PI / 2)
            {
                pitch = Mathf.PI - pitch;
            }
            else if (pitch < -Mathf.PI / 2)
            {
                pitch = -Mathf.PI - pitch;
            }

            yaw = Mathf.Atan2(vel.x, vel.z);

            hsp.VelocityVector = new Vector4(pitch,
                                            0,
                                            Mathf.Atan2(vel.x, vel.z),
                                            Rb.velocity.magnitude);
        }

        public void LateUpdate()
        {
            hsp.ApplyBlock();
        }

        public override void OnModuleSpawn()
        {
            DoInitHsp();
        }
    }

}
