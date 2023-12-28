using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OceanFFT : MonoBehaviour
{
    public Shader oceanShader;
    public ComputeShader fftShader;

    // Dispersion Relation

    // time domain: spits out a height given a time
    // frequency domain : spits out an ampltiude given a frequency

    // Phillips Spectrum data stored here
    public ComputeBuffer spectrumBuffer;

    // Directional Spread

    RenderTexture displacementMap, slopeMap, spectrumMap;

    // a texture is needed for initial_h_hat(k) so that h_hat(k, t) can be calculated
    // a texture is needed for h_hat(k, t), where k is a 2D pixel position vector and t is time
    // the frequency domain map also has a complex component for the phase
    // euler's formula is used for the spectrum map

    // heightMap calculated by summing up every h_hat(k) * e^(i * k * x) -> this is a texture, x being a position in the 2D map
    // derivativeMap calculated by summing up every h_hat(k) * i * k * e^(i * k * x) etc  -> this is a texture
    // -> or central difference approximation can work too

    public static RenderTexture CreateRenderTexture(int size, RenderTextureFormat format, bool useMips) {
        RenderTexture rt = new RenderTexture(size, size, 0,
            format, RenderTextureReadWrite.Linear);
        rt.anisoLevel = 6;
        rt.filterMode = FilterMode.Bilinear;
        rt.wrapMode = TextureWrapMode.Repeat;
        rt.useMipMap = useMips;
        rt.autoGenerateMips = false;
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }

    void OnEnable()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
