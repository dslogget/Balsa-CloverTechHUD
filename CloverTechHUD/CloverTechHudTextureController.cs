using System;
using UnityEngine;
using System.Collections;
using System.Linq;

namespace CloverTech
{
    class CloverTechHudTextureController : MonoBehaviour
    {
        public Texture2D toRender;
        public Material holoShader;
        public int horizonThickness = 2;
        public int horizonGap = 50;
        public float currentPitch = 0f;
        [Range(1, 45)]
        public float pitchIncrement = 5;
        [Range(1, 10)]
        public int numPitchMarkers = 1; // odd

        Color32[] pixelData;
        Color32 pixelCol;
        Color32 pixelColClear;

        int width = 50;
        int height = 100;

        public void Awake()
        {

        }

        public void Start()
        {
            holoShader = holoShader ?? FindObjectsOfType<Material>().ToList<Material>().Find(name => name.name == "HoloShader");
            toRender = new Texture2D(width, height, TextureFormat.ARGB32, false);
            toRender.filterMode = FilterMode.Point;
            toRender.wrapMode = TextureWrapMode.Clamp;
            holoShader.SetTexture("_MainTex", toRender);
            pixelData = new Color32[width * height];
            pixelCol = new Color32(0, 255, 0, 255);
            pixelColClear = new Color32(0, 0, 0, 0);

        }

        public void Update()
        {
            ClearPixels();
            DrawHorizon();
            DrawPitchMarkers();
        }
        public void FixedUpdate()
        {

        }
        public void LateUpdate()
        {
            toRender.SetPixels32(pixelData);
            toRender.Apply();

        }

        public void OnGui()
        {

        }

        public void OnDisable()
        {

        }

        public void OnEnable()
        {

        }

        public void OnValidate()
        {
        }

        private void ClearPixels()
        {
            for ( int i = 0; i < width*height; i++ )
            {
                pixelData[i] = pixelColClear;
            }
        }
        private void SetPixel(Vector2Int coord)
        {
            pixelData[coord.y * width + coord.x] = pixelCol;
        }

        private void SetPixel(int x, int y)
        {
            pixelData[y * width + x] = pixelCol;
        }

        private int PitchToHeight(float pitchIn)
        {

            int divisor = (numPitchMarkers + 1);
            // one step = height / ( 2*numPitchMarkers + 2 ) pixels
            // pix per degree = height / (( 2*numPitchMarkers + 2 ) * pitchIncrement )
            float pixPerDeg = height / ((2 * numPitchMarkers + 2) * pitchIncrement);


            return (int)( pixPerDeg * pitchIn ) + height / 2;
        }


        private void DrawPitchMarkers()
        {
            for ( int i = 0; i < numPitchMarkers; i++ )
            {
                int heightUp = PitchToHeight(pitchIncrement * (i + 1) - currentPitch);
                int heightDown = PitchToHeight(-pitchIncrement * (i + 1) - currentPitch);

                int pixOffset = (int)(0.3f * width);

                if ( heightUp > 0 && heightUp < height)
                {
                    BresenhamLine(pixOffset, heightUp, width - pixOffset, heightUp);
                }
                if (heightDown > 0 && heightDown < height)
                {
                    BresenhamLine(pixOffset, heightDown, width - pixOffset, heightDown);
                }

            }
        }
        private void DrawHorizon()
        {
            int gapPix = (int)(width * horizonGap / 200);
            int horizonLine = PitchToHeight(-currentPitch);
            for (int i = 0; i < horizonThickness; i++)
            {

                
                BresenhamLine(new Vector2Int(0, i+ horizonLine),
                               new Vector2Int(width / 2 - gapPix, i + horizonLine));
                BresenhamLine(new Vector2Int(width / 2 + gapPix, i + horizonLine),
                               new Vector2Int(width, i + horizonLine));
            }
        }

        private void PlotLineLow(Vector2Int start, Vector2Int end)
        {
            Vector2Int d = end - start;
            if (d.x == 0)
            {
                for (int x = start.x; x < end.x; ++x)
                {
                    SetPixel(x, start.y);
                }
                return;
            }

            int yi = 1;
            if (d.y < 0)
            {
                yi = -1;
                d.y = -d.y;
            }
            int acc = 2 * d.y - d.x;
            int y = start.y;

            for ( int x = start.x; x < end.x; ++x )
            {
                SetPixel(x, y);
                if (acc > 0)
                {
                    y = y + yi;
                    acc = acc + (2 * (d.y - d.x));
                } 
                else
                {
                    acc = acc + 2 * d.y;
                }
            }
        }
        private void PlotLineHigh(Vector2Int start, Vector2Int end)
        {
            Vector2Int d = end - start;
            if (d.y == 0)
            {
                for (int y = start.y; y < end.y; ++y)
                {
                    SetPixel(start.x, y);
                }
                return;
            }


            int xi = 1;
            if (d.x < 0)
            {
                xi = -1;
                d.x = -d.x;
            }
            int acc = 2 * d.x - d.y;
            int x = start.x;

            for (int y = start.y; y < end.y; ++y)
            {
                SetPixel(x, y);
                if (acc > 0)
                {
                    x = x + xi;
                    acc = acc + (2 * (d.x - d.y));
                }
                else
                {
                    acc = acc + 2 * d.x;
                }
            }
        }
        private void BresenhamLine(Vector2Int start, Vector2Int end)
        {
            Vector2Int diff = end - start;
            if (diff.x == 0 && diff.y == 0)
            {
                return;
            }   

            if (Math.Abs(diff.y) < Math.Abs(diff.x))
            {
                if (start.x > end.x)
                {
                    PlotLineLow(end, start);
                }
                else
                {
                    PlotLineLow(start, end);
                }
            }
            else
            {
                if (start.y > end.y)
                {
                    PlotLineHigh(end, start);
                }
                else
                {
                    PlotLineHigh(start, end);
                }
            }
        }
        private void BresenhamLine(int x0, int y0, int x1, int y1)
        {
            BresenhamLine(new Vector2Int(x0, y0), new Vector2Int(x1, y1));
        }

        private void DrawLine(Vector2 start, Vector2 end)
        {
            Vector2Int startInt = new Vector2Int(((int)(width * start.x) + width)/2, ((int)(height * start.y) + height) / 2);
            Vector2Int endInt = new Vector2Int(((int)(width * end.x) + width) / 2, ((int)(height * end.y) + height) / 2);
            startInt.Clamp(new Vector2Int(1, 1), new Vector2Int(width - 1, height - 1));
            endInt.Clamp(new Vector2Int(1, 1), new Vector2Int(width - 1, height - 1));
            BresenhamLine(startInt, endInt);
        }

        private void DrawLine(float x0, float y0, float x1, float y1)
        {
            DrawLine(new Vector2(x0, y0), new Vector2(x1, y1));
        }

    }
}
