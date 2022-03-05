using System;
using UnityEngine;
using System.Collections;
using System.Linq;

namespace CloverTech
{
    class CloverTechHudTextureController_new : MonoBehaviour
    {
        public MeshRenderer meshRend;
        public Material[] matList;
        public string name;
        public Texture centreRender;
        public Texture pitchRender;
        public Texture rollRender;
        public Texture yawRender;
        public Material holoShader;


        public void Awake()
        {

        }

        public void Start()
        {
            meshRend = GetComponentInParent<MeshRenderer>();
            matList = meshRend.materials;
            holoShader = GetComponentInParent<MeshRenderer>().materials.ToList().Find(mat => mat.name.Contains("NewHoloShader"));
            centreRender = holoShader.GetTexture("_CentreTex");
            pitchRender = holoShader.GetTexture("_PitchTex");
            rollRender = holoShader.GetTexture("_RollTex");
            yawRender = holoShader.GetTexture("_YawTex");
            centreRender.filterMode = FilterMode.Bilinear;
            centreRender.wrapMode = TextureWrapMode.Clamp;
            pitchRender.filterMode = FilterMode.Bilinear;
            pitchRender.wrapMode = TextureWrapMode.Clamp;
            pitchRender.wrapModeV = TextureWrapMode.Clamp;
            rollRender.filterMode = FilterMode.Bilinear;
            rollRender.wrapMode = TextureWrapMode.Clamp;
            yawRender.filterMode = FilterMode.Bilinear;
            yawRender.wrapMode = TextureWrapMode.Clamp;
            yawRender.wrapModeV = TextureWrapMode.Repeat;
        }

        public void Update()
        {

        }
        public void FixedUpdate()
        {

        }
        public void LateUpdate()
        {


        }

        public void OnPreRender()
        {

        }

        public void OnValidate()
        {
        }


    }
}
