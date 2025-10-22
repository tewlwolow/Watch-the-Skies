// Volumetric sun shafts - banding removed
// Compatible with MGE XE, screen-space radial method

int mgeflags = 9;

// tweakables
#define N 50                     // more samples for smoother rays
#define raysunradius 0.36
#define raystrength 1.85
#define rayfalloff 1.7
#define rayfalloffconst 0.21
#define raysunfalloff 2.2        // stronger volumetric fade
#define centervis 0.25
#define sunrayocclude 0.8
#define brightnessadd 1.15
#define offscreenrange 0.8
#define sundisc 1
#define sundiscradius 0.027
#define sundiscbrightness 1.3
#define sundiscdesaturate 0.7
#define sundiscocclude 0.73
#define horizonclipping 1

texture depthframe;
texture lastshader;
texture lastpass;

sampler s0 = sampler_state { texture = <depthframe>; minfilter = point; magfilter = point; addressu = clamp; addressv = clamp; };
sampler s1 = sampler_state { texture = <lastshader>; minfilter = point; magfilter = point; addressu = clamp; addressv = clamp; };
sampler s2 = sampler_state { texture = <lastpass>; minfilter = linear; magfilter = linear; addressu = clamp; addressv = clamp; };

float3 suncol;
float3 eyevec;
float3 eyepos;
float3 sunpos;
float sunvis;
float2 rcpres;
float waterlevel;
float fogstart;
float fogrange;
float fov;

matrix mview;
matrix mproj;

static const float raspect = rcpres.x / rcpres.y;
static const float forward = dot(-normalize(sunpos), eyevec);
static const float2 texproj = 0.5 * float2(1, -rcpres.y/rcpres.x) / tan(radians(fov*0.5));
static const float3 sunview_v = mul(sunpos / dot(eyevec,sunpos), mview);
static const float2 sunview = (0.5).xx + sunview_v.xy * texproj;
static const float2 sunviewhalf = 0.5 * sunview;

static const float light = 1 - pow(1 - sunvis, 2);
static const float sharpness = lerp(60, 660 + 360 * (-normalize(sunpos).z), saturate(fogstart / 480));
static const float strength = raystrength * light * smoothstep(-offscreenrange,0,0.5-abs(sunview.x-0.5)) * smoothstep(-offscreenrange,0,0.5-abs(sunview.y-0.5));
static const float oneminuscentervis = 1-centervis;
static const float3 suncoldisc = float3(1, 0.76+0.24*sunpos.z, 0.54+0.46*sunpos.z) * saturate(suncol/max(suncol.r,max(suncol.g,suncol.b))*(1-sundiscdesaturate)+float3(sundiscdesaturate,sundiscdesaturate,sundiscdesaturate));
static const float aziHorizon = normalize(float2(4*fogrange, waterlevel-eyepos.z)).y;

static const float scale = 2.0;
static const float rscale = 0.5;
static const float threshold = 1e7;

float4 sample0(sampler2D s, float2 t) { return tex2Dlod(s,float4(t,0,0)); }

float4 stretch(float2 Tex: TEXCOORD0) : COLOR0
{
    clip(1.1*rscale - Tex);
    float depth = 0;
    if(forward < 0)
    {
        float2 srcTex = scale*Tex;
        depth = step(threshold,sample0(s0,srcTex).r);
        depth += step(threshold,sample0(s0,srcTex+float2(rcpres.x,0)).r);
        depth += step(threshold,sample0(s0,srcTex+float2(0,rcpres.y)).r);
        depth += step(threshold,sample0(s0,srcTex+float2(rcpres.x,rcpres.y)).r);
        depth *= 0.25;
    }
    return float4(0,0,0,depth);
}

float4 blurRHalf(float2 Tex: TEXCOORD0) : COLOR0
{
    clip(1.1*rscale-Tex);
    if(forward >= 0) return 0;
    float2 radial = normalize(Tex - sunviewhalf).xy * rcpres.yx;
    float alpha = 0.3333*sample0(s2,Tex).a;
    alpha += 0.2222*sample0(s2,Tex+radial).a;
    alpha += 0.2222*sample0(s2,Tex-radial).a;
    alpha += 0.1111*sample0(s2,Tex+2*radial).a;
    alpha += 0.1111*sample0(s2,Tex-2*radial).a;
    return float4(0,0,0,alpha);
}

// ======================== SCREEN-SPACE VOLUMETRIC RAYS ========================
float4 rays(float2 Tex: TEXCOORD0) : COLOR0
{
    if(forward >= 0) return 0;

    float2 dir = Tex - sunview;
    float dist = length(dir * float2(1, raspect));
    dir /= max(dist, 1e-5);

    float l = 0;

    for(int i=1; i<=N; i++)
    {
        float t = float(i)/float(N);
        float offset = t * min(raysunradius, dist);
        float sampleA = sample0(s2, saturate(Tex - offset*dir)*rscale).a;

        float fade = exp(-((dist - offset)/(rayfalloffconst+offset))*rayfalloff);
        float taper = pow(1.0 - offset/raysunradius, 3.0);
        float bias = 0.25*(1.0 - t);

        l += sampleA * fade * (taper + bias)/N;
    }

    l *= strength * (dist/raysunradius*oneminuscentervis + centervis);
    l = saturate(l);

    float4 col = float4(suncol.r,0.8*suncol.g,0.8*suncol.b,l);
    col.rgb *= 1 + brightnessadd * pow(col.a,3);

    // subtle dithering to remove banding
    float dither = (frac(sin(dot(Tex.xy,float2(12.9898,78.233)))*43758.5453)-0.5)*0.001;
    col.rgb = saturate(col.rgb + dither);

    return col;
}
// ==========================================================================

float4 blurT(float2 Tex: TEXCOORD0) : COLOR0
{
    if(forward >= 0) return 0;
    float2 tangent = normalize(Tex - sunview).yx * float2(rcpres.y,-rcpres.x);
    float4 col = 0.3333*sample0(s2,Tex);
    col += 0.2222*sample0(s2,Tex+tangent);
    col += 0.2222*sample0(s2,Tex-tangent);
    col += 0.1111*sample0(s2,Tex+2*tangent);
    col += 0.1111*sample0(s2,Tex-2*tangent);
    return col;
}

float4 blurR(float2 Tex: TEXCOORD0) : COLOR0
{
    if(forward >= 0) return 0;
    float2 radial = 3.0*normalize(Tex-sunview).xy*rcpres.yx;
    float4 col = 0.3333*sample0(s2,Tex);
    col += 0.2222*sample0(s2,Tex+radial);
    col += 0.2222*sample0(s2,Tex-radial);
    col += 0.1111*sample0(s2,Tex+2*radial);
    col += 0.1111*sample0(s2,Tex-2*radial);
    return col;
}

float3 toWorld(float2 tex)
{
    float3 v = float3(mview[0][2],mview[1][2],mview[2][2]);
    v += (1/mproj[0][0]*(2*tex.x-1)).xxx*float3(mview[0][0],mview[1][0],mview[2][0]);
    v += (-1/mproj[1][1]*(2*tex.y-1)).xxx*float3(mview[0][1],mview[1][1],mview[2][1]);
    return v;
}

float4 combine(float2 Tex: TEXCOORD0) : COLOR0
{
    float4 ray = sample0(s2,Tex);
    float3 col = sample0(s1,Tex);
    col *= saturate(1 - sunrayocclude * ray.a);
    col = saturate(col + ray.rgb * ray.a);

#if sundisc == 1
    if(forward < 0)
    {
        float2 sd = Tex - sunview;
        sd.y *= raspect;
        float occl = light * step(threshold, sample0(s0,Tex).r);
        occl *= smoothstep(0.0,1.0,exp2(sharpness*(sundiscradius-length(sd))));
        if(occl > 0.004)
        {
            float3 scol = suncoldisc*sundiscbrightness;
#if horizonclipping == 1
            float azi = normalize(toWorld(Tex)).z;
            occl *= smoothstep(-0.005,0.01,azi-aziHorizon);
            scol.gb *= smoothstep(-0.04,0.09,azi-aziHorizon);
#endif
            col = lerp(col,scol,sundiscocclude*occl);
        }
    }
#endif

    return float4(col,1);
}

float4 alpha(float2 Tex:TEXCOORD0) : COLOR0
{
    float a = sample0(s2,Tex).a;
    return float4(a,a,a,1);
}

technique T0 <string MGEinterface="MGE XE 0"; bool disableSunglare = true;>
{
    pass {PixelShader = compile ps_3_0 stretch();}
    pass {PixelShader = compile ps_3_0 blurRHalf();}
    pass {PixelShader = compile ps_3_0 rays();}
    pass {PixelShader = compile ps_3_0 blurT();}
    pass {PixelShader = compile ps_3_0 combine();}
}
