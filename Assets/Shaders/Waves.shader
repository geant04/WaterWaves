Shader "Custom/Waves"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Cube ("Cubemap", CUBE)  = "" {}
        _Amplitude ("Amplitude", Float) = 1.0
        _Wavelength ("Wavelength", Range(0, 10)) = 1
        _Speed ("Speed", Range(0, 10)) = 1
        _Light ("Light Color", Color) = (1,1,1,1)
        _Color ("Color", Color) = (1,1,1,1)
        _AmbientColor ("Ambient Color", Color) = (1,1,1,1)
        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _SunColor ("Sun Color", Color)  = (1,1,1,1)
        _specularShine ("Shininess", Range(0, 100)) = 14.0
        _FresnelShine ("Fresnel Shininess",  Range(0, 100)) = 14.0
        _ReflectionStrength("Reflection Strength", Range(0, 10)) = 0.0
        _ReflectionOffset("Reflection Offset", Range(-1, 1)) = 0.0
        _Waves ("Waves", Float) = 1.0
        _Octaves ("Octaves", Float) = 1.0
        _NormalBias ("Normal Bias", Range(0, 10)) = 5.0
        _FreqChange ("Freq Change", Float) = 1.18
        _AmpChange ("Amp Change", Float) = 0.60
        _WavelengthChange ("Wavelength Change", Float) = 0.67

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Water fullforwardshadows vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;
        samplerCUBE _Cube;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldRefl;
        };

        float random (float u, float v)
        {
            float2 uv = float2(u, v);
            return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
        }
        
		half _Glossiness;
		half _Metallic;

        fixed4 _Color, _Light, _AmbientColor, _FresnelColor, _SunColor;
        float _Amplitude, _Wavelength, _Speed, _specularShine, _FresnelShine, _ReflectionStrength, _NormalBias, _ReflectionOffset,
              _FreqChange, _AmpChange, _WavelengthChange;
        half _Waves, _Octaves;

        half4 LightingWater (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
            float4 lightColor = _Light;

            // viewIndependentColor color section

            float ambientStrength = 0.25;
            float3 ambient = _AmbientColor * ambientStrength;

            float diff = max(dot(s.Normal, lightDir), 0.0) * 0.50;
            float3 diffuse = diff * lightColor;

            float3 viewIndependentColor = (ambient + (diffuse * diffuse)) * s.Albedo;

            // viewDependentColor color section

            half3 halfwayDir = normalize(lightDir + viewDir);

            
            float shininess = _specularShine;
            float nh = max(0.0, dot(s.Normal, halfwayDir));
            float spec = pow(nh, shininess * shininess);

            // blinn phong
            float fbase = 1 - (dot(viewDir, halfwayDir));
            float R = pow(fbase, 5.0) + 0.20;

            spec *= R + 8.0 * R;
            float3 highlights = lightColor.rgb * spec;
            
            // reflection + fresnel
            float3 reflectionNormal = normalize(s.Normal + float3(0.0, _NormalBias, 0.0));
            float3 reflect = -viewDir + 2 * (dot(reflectionNormal, viewDir)) * reflectionNormal;
            float3 cubeMapColor = texCUBE(_Cube, reflect).rgb;
            float3 additionalDiffuse = dot(reflectionNormal, viewDir) * 0.5 + 0.5;

            float3 sun = _SunColor * pow(max(0.0f, DotClamped(reflect, lightDir)), 500.0f);

            float fdot = 1 - dot(viewDir, s.Normal);
            float fresnelSpec = pow(fdot, _FresnelShine);

			float3 fresnel = cubeMapColor.rgb * additionalDiffuse * fresnelSpec * _FresnelColor;
			fresnel += sun * fresnelSpec;
            fresnel *= _ReflectionStrength;
            fresnel += _ReflectionOffset;
            //fresnel += 0.4;
            //fresnel *= 2.3;

            // sum it all together
            float3 viewDependentColor = highlights + fresnel;

            half4 c;
            c.rgb = viewIndependentColor + viewDependentColor;
            c.a = s.Alpha;

            return c;
        }

        float FBMSineWave(float4 wave, float3 p, 
                            inout float tangent, inout float binormal, 
                            inout float2 prevPartial, float waveNumber, float hash) {
            // x,y = direction
            // w = amplitude, z = speed?
            // p is the position
            float2 d = normalize(wave.xy);
            float amp = wave.z;
            float freq = wave.w;
            float h = 0.0;
            float wavelength = (_Wavelength * 100) * (random(wave.y, 0) + random(wave.x, 0));

            for(int i = 0; i < _Octaves; i++) {
                float xz = dot(d, p.xz + prevPartial);
                float omega = 0.8 * UNITY_PI / wavelength;

			    h += amp * sin(omega * xz + _Time.y * freq);

                prevPartial.x = amp * omega * cos(omega * xz + _Time.y * freq);
                prevPartial.y = amp * freq * cos(omega * xz + _Time.y * freq);

                tangent += prevPartial.x;
                binormal += prevPartial.y;

                freq *= _FreqChange;
                amp *= _AmpChange;
                wavelength *= _WavelengthChange;
            }

            return h;
        }

        void vert(inout appdata_full vertexData) {
            float3 p = vertexData.vertex.xyz;
            float dx = 0.0;
            float dz = 0.0;
            float2 prevPartial = float2(0.0, 0.0);

            for(int i = 0; i < _Waves; i++) {
                float hash = random(i, 0);
                float2 dir = float2(random(hash, hash) - 0.5, random(hash + 1, hash - 1) - 0.5);

                float randAmp = abs(random(i, i) + 0.5);
                float randSpeed = abs(2.0 * (random(i+4, i * 10)));

                float4 wave = float4(dir.x, dir.y, 
                                    _Amplitude * 2.0 * randAmp, 
                                    _Speed * randSpeed);

                p.y += FBMSineWave(wave, p, dx, dz, prevPartial, i, hash);
            }

            float3 tangent = float3(1.0, 0.0, dx);
            float3 binormal = float3(0.0, 1.0, dz);

			float3 normal = normalize(cross(binormal, tangent));
			vertexData.vertex.xyz = p;
			vertexData.normal = normal;
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
