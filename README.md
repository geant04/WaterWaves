# Real-Time FBM Water Shader
This is a real-time FBM water Shader inspired by Acerola's ocean simulation video. The shader is entirely written using Unity's Shaderlab and uses a cubemap by Render Knight.
The shader modifies the vertices to follow many sine waves summed together and uses a fragment shader to detail the water.

Fun things I implemented so far:
- Fractal Brownian Motion on a sum of sines
- Blinn Phong specular highlights
- Lambertian diffuse and ambience
- Fresnel reflections using Cubemap reflections
<!-- end of the list -->
What I plan on implementing next:
- Fast Fourier Transforms (reduce tiling and get more waves)
- Subsurface scattering (helps the water lighting)
- Foam

## Sum of Sines
To simualte realistic water, we sum together several different 3D sine functions of varying direction. Each sine wave has an amplitude, a frequency, and a wavelength.
- Amplitude: determines the "size" of the wave
- Frequency: The oscillation speed
- Wavelength: Length of the wave for a full period to finish
<!-- end of the list -->
I included a parameter for people to put in as many waves as they want (more waves will negatively impact performance).
Currently, I am trying to find better ways of randomizing the parameters of the generated waves, such as varying the amplitude more etc.

## FBM on the Waves
To get finer details, we use Fractal Brownian Motion and Domain Warping to make the water look more noisy and turbulent (see here: https://thebookofshaders.com/13/). 
My shader has an "octaves" parameter which you can use to get finer details and knobs for lacunarity, gain, etc.

## Calculating Normals
Because we deform vertices, we need to re-calculate the normals for the fragment shader. This is done by summing all the partial derivatives for the x and z components of the sine waves
when we modify the height of a vertex. The partial derivative components are respectively placed in tanget and binormal vectors, which we then do a cross product and normalize to get our final normal.

The approach comes from an NVIDIA GPU Gems article: https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models

## Surface Shading the Waves
I applied a custom lighting model on the waves to surface shade it, which is comprised of a view-independent color and a view-dependent color.
The view-independent color is an ambient and a lambertian diffuse summed together and then multiplied by the albedo of the water (albedo and ambient colors can be adjusted).

The view-dependent color uses Blinn-Phong specular highlights and Fresnel reflections. Reflections are done by getting a reflection vector from the view vector and the surface normal.
We put the reflection vector in a cubemap sampler from our skybox, and then the intensity of the reflection gets determined by our view angle from the normal.

There are several other parameters you can fiddle with that affect the overall lighting, but in the end we sum the view-independent and view-dependent colors together to get the color of the water.

