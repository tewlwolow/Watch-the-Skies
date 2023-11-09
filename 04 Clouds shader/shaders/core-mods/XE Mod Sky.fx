
// XE Mod Sky.fx
// MGE XE 0.16.0
// Sky and cloud rendering. Can be used as a core mod.

// Ordered dithering matrix
static const float ditherSky[4][4] = { 0.001176, 0.001961, -0.001176, -0.001699, -0.000654, -0.000915, 0.000392, 0.000131, -0.000131, -0.001961, 0.000654, 0.000915, 0.001699, 0.001438, -0.000392, -0.001438 };

//------------------------------------------------------------
// Sky and sky reflections

struct SkyVertOut {
    float4 pos : POSITION;
    float4 color : COLOR0;
    float2 texcoords : TEXCOORD0;
    float4 skypos : TEXCOORD1;
};

SkyVertOut SkyVS(StatVertIn IN) {
    SkyVertOut OUT;
    float4 pos = IN.pos;

    // Screw around with skydome, align default mesh with horizon
    if(!hasAlpha) {
        pos.z = 50 * (IN.pos.z + 200);
    }

    pos = mul(pos, world);
    OUT.skypos = float4(pos.xyz - eyePos, 1);

    pos = mul(pos, view);
    OUT.pos = mul(pos, proj);
    OUT.pos.z = 0.999999 * OUT.pos.w;   // Pin z to far plane so it renders to background
    OUT.color = IN.color;
    OUT.texcoords = IN.texcoords;

    return OUT;
}

float4 SkyPS(SkyVertOut IN, float2 vpos : VPOS) : COLOR0 {
    float4 c = 0;

    if(hasAlpha) {
        if (hasBones) {
            // Sun/moon billboard. Sample texture at lod 0 avoiding mip blurring
            c = tex2Dlod(sampBaseTex, float4(IN.texcoords, 0, 0));
        }
        else {
            // Standard texture filtering
            c = tex2D(sampBaseTex, IN.texcoords);
        }
        c *= IN.color;
    }

    if(hasVCol) {
        // Moon shadow cutout. Use colour from scattering for sky (but preserves alpha)
        float4 f = fogColourSky(normalize(IN.skypos.xyz));
        c.rgb = f.rgb + ditherSky[vpos.x % 4][vpos.y % 4];
    }

    return c;
}

//------------------------------------------------------------
// Clouds


//------------
// Vertex cloud shader

SkyVertOut CloudsVS(StatVertIn IN) {
    return SkyVS(IN);
}


//------------
// Pixel cloud shader

// Controls the initial displacement when sampling cloud textures
float disSample = 0.02;

// Controls the displacement of the clouds. Higher = more 'fragmented'
float dis1 = 8.1;
float dis2 = 4.1;
float dis3 = 0.021;

// Controls the time factor for displacement. Higher = faster
float timeFactor = 0.008;

// Controls additional sun colour saturation for the clouds. Higher = more sun colour influence
float sunColSat = 0.6;

// Controls the further clouds colour saturation with sun ambient colour. Higher = more sun ambient colour influence
float sunAmbMult = 2;

// Controls the factor for output saturation with sun colour, basically a sort of contrast modifier
float incolFactor = 0.5;


// Pixel cloud shader
// Clouds rendering from XE Mod Sky by Dexter (vtastek) ported to MGE XE >= 0.16.0 and edited by tewlwolow

float4 CloudsPS(SkyVertOut IN) : COLOR0 {
    float4 c = 0; // Final color output
    float4 clouds = 0; // Accumulated cloud color
    int N = 8; // Number of iterations for cloud sampling
    float3 eyeV = normalize(IN.skypos.xyz); // Normalized eye vector

    // Iterate for cloud sampling
    for (int i = 1; i <= N; i++)
    {
        float sd = (float)i / (float)N;
        // Sample cloud texture and accumulate with exponential decay
        clouds += exp(-sd * 0.1) * tex2Dlod(sampBaseTex, float4(IN.texcoords + disSample * (1 + sd) * (eyeV), 0, 0));
    }
    // Average the accumulated cloud color
    clouds /= (float)N;
    // Ensure cloud color is within valid range
    clouds = saturate(1 - clouds);

    // Sample additional cloud textures for displacement
    float4 tur = tex2Dlod(sampBaseTex, float4(IN.texcoords * dis1 + float2(time * timeFactor, time * (timeFactor + 0.002)), 0, 0));
    float4 tur2 = tex2Dlod(sampBaseTex, float4(IN.texcoords * dis2 + float2(time * timeFactor, time * (timeFactor + 0.0023)), 0, 0));

    // Sample main cloud texture with displacement
    float4 ca = tex2Dlod(sampBaseTex, float4(IN.texcoords + dis3 * tur.r * tur2.a, 0, 0));

    // Apply a light blur to the displacement map
    float blurAmount = 0.006; // Adjust the blur amount as needed
    float4 blurredCa = tex2Dlod(sampBaseTex, float4(IN.texcoords + blurAmount * (tur.r + tur2.a), 0, 0));

    // Interpolate between the original and blurred displacement
    ca.rgb = lerp(ca.rgb, blurredCa.rgb, 0.2); // Adjust the interpolation factor as needed

    // Adjust cloud color based on sun and ambient light
    clouds.rgb = lerp(saturate(sunAmb * sunAmbMult), sunCol + sunColSat, clouds.rgb);

    // Get fogColourSky
    float4 fogColor = fogColourSky(normalize(IN.skypos.xyz));

    // Blend fog color with cloud color so we keep the influence of fog colour on clouds
    clouds.rgb = lerp(clouds.rgb, fogColor.rgb, fogColor.a);

    // Multiply by sun-influenced color, preserving alpha
    clouds.rgb = ca.rgb * clouds.rgb * ca.a;
    clouds.a = ca.a;

    // Calc sunlight coefficients
    float sunrim = clouds.r - 0.1;
    float sund = max(0,dot(eyeV, normalize(sunPos)));
    float sunarea = (1 - pow(sund, 52));
    float sunarea2 = (1 - pow(sund, 11105));

    // Create a 'halo' effect by adjusting input color
    float4 incol = IN.color;
    incol.rgb += (1.5 + sunrim + sunarea2) * (1 - sunarea) * smoothstep(0.1, 0.5, ca.a);

    // Combine input color with the lerped cloud color based on sun color
    c = incol * lerp(ca, clouds, sunCol.r * incolFactor);

    return c; // Final color output
}