
// XE Mod Sky.fx
// MGE XE 0.13.0
// Sky rendering. Can be used as a core mod.

//------------------------------------------------------------
// Sky and sky reflections

// By Dexter (vtastek), modified by tewlwolow

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

// Ordered dithering matrix
static const float ditherSky[4][4] = { 0.001176, 0.001961, -0.001176, -0.001699, -0.000654, -0.000915, 0.000392, 0.000131, -0.000131, -0.001961, 0.000654, 0.000915, 0.001699, 0.001438, -0.000392, -0.001438 };

float4 SkyPS(SkyVertOut IN, float2 vpos : VPOS) : COLOR0 {
    float4 c = 0;

    if(hasAlpha) {
        // Sample texture at lod 0 avoiding mip blurring

		float4 clouds = 0;// tex2Dlod(sampBaseTex, float4(IN.texcoords - normalize(eyePos - sunPos), 0, 0));
		int N = 8;
		float3 eyeV = normalize(IN.skypos.xyz);
		for(int i = 1; i <= N; i++)
		{
			float sd = (float)i / (float)N;

			clouds += exp(-sd * 0.1) * tex2Dlod(sampBaseTex, float4(IN.texcoords + 0.05 * (1 + sd) * (eyeV), 0, 0)).a;
		}
		clouds /= (float)N;
		clouds = saturate(1-clouds);

		float sunrim = clouds.r - 0.1;
		float sund = max(0,dot(eyeV, normalize(sunPos)));
		float sunarea = (1 - pow(sund, 52));
		float sunarea2 = (1 - pow(sund, 11105));
		float4 tur = tex2Dlod(sampBaseTex, float4(IN.texcoords * 10.1 - time * 0.01, 0, 0));
		float4 tur2 = tex2Dlod(sampBaseTex, float4(IN.texcoords * 5.1 - time * 0.01, 0, 0));

		float4 ca = tex2Dlod(sampBaseTex, float4(IN.texcoords + 0.02 * tur.r  * tur2.a , 0, 0));
		clouds.rgb = lerp(saturate(sunAmb * 2), sunCol + 0.4, clouds.rgb);
		//clouds.rgb = clouds.rgb * sunarea + sunrim * sunarea;

		clouds.rgb = ca.rgb * 0.85 * clouds.rgb * ca.a;

		clouds.a = ca.a;
		float4 incol = IN.color;
		incol.rgb += (1.5 + sunrim + sunarea2) * (1-sunarea) * smoothstep(0.1,0.5,ca.a);

        c = incol * lerp(ca, clouds, sunCol.r);
    }

    if(hasBones) {
        // Use colour from scattering for sky (but preserves alpha)
        float4 f = fogColourSky(normalize(IN.skypos.xyz)) + ditherSky[vpos.x % 4][vpos.y % 4];
        c.rgb = f.rgb;
    }

    return c;
}
