
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
// Clouds rendering from XE Mod Sky by Dexter (vtastek) ported to MGE XE >= 0.16.0 and edited by tewlwolow

// Controls the initial displacement when sampling cloud textures
float disSample = 0.02;

// Controls the displacement of the clouds. Higher = more 'fragmented'
float dis1 = 7.0;
float dis3 = 0.012;

// Controls the time factor for displacement. Higher = faster
float timeFactor = 0.0058;

// Controls the further clouds colour saturation with sun ambient colour. Higher = more sun ambient colour influence
float sunAmbMult = 2;

// Controls the factor for output saturation with sun colour, basically a sort of contrast modifier
float incolFactor = 0.4;

float4 CloudsPS(SkyVertOut IN) : COLOR0 {
    float4 c = 0; // Final color output
    float4 clouds = 0; // Accumulated cloud color
    int N = 4; // Number of iterations for cloud sampling
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
    float4 tur = tex2Dlod(sampBaseTex, float4(IN.texcoords * dis1 - float2(time * timeFactor, time * timeFactor), 0, 0));
    float4 tur2 = tur/2;

    // Sample main cloud texture with displacement
    float4 ca = tex2Dlod(sampBaseTex, float4(IN.texcoords - dis3 * tur.r * tur2.a, 0, 0));

    // Adjust cloud color based on sun and ambient light
    clouds.rgb = lerp(saturate(sunAmb * sunAmbMult), sunCol, clouds.rgb);

    // Get fogColourSky
    float4 fogColor = fogColourSky(normalize(IN.skypos.xyz));

    // Blend fog color with cloud color so we keep the influence of fog colour on clouds
    clouds.rgb = lerp(clouds.rgb, fogColor.rgb, 0.8);

    // Multiply by sun-influenced color, preserving alpha
    clouds.rgb = ca.rgb * clouds.rgb * ca.a;
    clouds.a = ca.a;

    // Calc sunlight coefficients
    float sunrim = clouds.r - 0.2;
    float sund = max(0, dot(eyeV, normalize(sunPos)));
    float sunarea = (1 - pow(sund, 52));
    float sunarea2 = sunarea/12;

    // Create a 'halo' effect by adjusting input color
    float4 incol = IN.color;
    incol.rgb += (0.85 + sunrim + sunarea2) * (1 - sunarea) * ca.a;

    // Combine input color with the lerped cloud color based on sun color
    c = incol * lerp(ca, clouds, sunCol.r * incolFactor);

    return c; // Final color output
}
