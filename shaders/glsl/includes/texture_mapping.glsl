#include "../uniformPerFrameConstants"
#include "../uniformShaderConstants"

    vec3 rotateNormals(vec3 baseNormal, vec3 normalMap){
        // Fake TBN transformations for normalmapps
        // TODO: Weird thing and takes alot of performance because of branching
        // TODO: Needs refactoring
        if(length(normalMap) > 0.9){
            
            float normalMapStrength = 2.0;

            if(baseNormal.g > 0.9){
                normalMap.gb = normalMap.bg;
                normalMap = normalMap * 2.0 - 1.0;
                normalMap.rb *= normalMapStrength;
                baseNormal = normalize(normalMap);
            }else{
                if(baseNormal.g < -0.9){
                    normalMap.b = -normalMap.b;
                    normalMap.gb = normalMap.bg;
                    normalMap = normalMap * 2.0 - 1.0;
                    normalMap.rb *= normalMapStrength;
                    baseNormal = normalize(normalMap);
                }else{
                    if (baseNormal.b > 0.9){
                        normalMap.g = 1.0 - normalMap.g;// OpenGl needs G to be flipped
                        normalMap = normalMap * 2.0 - 1.0;
                        normalMap.rg *= normalMapStrength;
                        baseNormal = normalize(normalMap);
        
                    }else{
                        if(baseNormal.b < -0.9){
                            normalMap.b = -normalMap.b;
                            normalMap.g = 1.0 - normalMap.g;// OpenGl G flip
                            normalMap.r = 1.0 - normalMap.r;
                            normalMap.rg = normalMap.rg * 2.0 - 1.0;
                            normalMap.b = normalMap.b * 2.0 + 1.0;
                            normalMap.rg *= normalMapStrength;
                            baseNormal = normalize(normalMap);
                        }else{
                            if(baseNormal.r > 0.9){
                                normalMap.g = 1.0 - normalMap.g;// OpenGl G flip
                                normalMap.r = 1.0 - normalMap.r;
                                normalMap.rb = normalMap.br;
                                normalMap = normalMap * 2.0 - 1.0;
                                normalMap.gb *= normalMapStrength;
                                baseNormal = normalize(normalMap);
                            }else{
                                if(baseNormal.r < -0.9){
                                    normalMap.b = -normalMap.b;
                                    normalMap.g = 1.0 - normalMap.g;//OpenGl G flip
                                    normalMap.rb = normalMap.br;
                                    normalMap.gb = normalMap.gb * 2.0 - 1.0;
                                    normalMap.r = normalMap.r * 2.0 + 1.0;
                                    normalMap.gb *= normalMapStrength;
                                    baseNormal = normalize(normalMap);
                                }
                            }
                        }
                    }
                }
            }
        }
        return baseNormal;
    }

    vec3 mapWaterNormals(sampler2D texture0){
		highp float t = TIME * 0.1;
		float wnScale = 1.0;
		vec2 waterNormalOffset = vec2(4.0/32.0, 0.0);

		// TODO resolve interpolation issues on edges using a more correct way (currently it is wierd)
		vec3 normalMap = texture2D(texture0, fract(position.xz*1.0*wnScale + t*wnScale * 2.0)/33.0 + waterNormalOffset).rgb;
		normalMap += texture2D(texture0, fract(position.xz*0.5*wnScale - t*wnScale * 1.5)/33.0 + waterNormalOffset).rgb;// 
		normalMap += texture2D(texture0, fract(position.xz*0.25*wnScale + t*wnScale * 1.15)/33.0 + waterNormalOffset).rgb;
		normalMap += texture2D(texture0, fract(position.xz*0.125*wnScale - t*wnScale*0.9)/33.0 + waterNormalOffset).rgb;
		
		return normalMap * 0.25;
    }

    float mapPuddles(sampler2D texture0, vec2 position, float isRain){
        float puddlesSharpness = 2.0;
		float puddlesCovering = 1.5;
		float puddlesScale = 32.0;
		float minRainWettneess = 0.25;

		vec2 noiseTextureOffset = vec2(1.0/32.0, 0.0); 
		float puddles = texture2D(texture0, fract(position  / puddlesScale)/32.0 + noiseTextureOffset).r;
		puddles = pow(puddles * isRain * puddlesCovering, puddlesSharpness);
		puddles = clamp(puddles, minRainWettneess, 1.0);

		return puddles * pow(uv1.y, 2.0);// No puddles in dark places like caves
    }

    float mapCaustics(sampler2D texture0, vec3 position){
        highp float time = TIME;
		highp float causticsSpeed = 0.05;
		float causticsScale = 0.1;
		
		highp vec2 cauLayerCoord_0 = (position.xz + vec2(position.y / 8.0)) * causticsScale + vec2(time * causticsSpeed);
		highp vec2 cauLayerCoord_1 = (-position.xz - vec2(position.y / 8.0)) * causticsScale*0.876 + vec2(time * causticsSpeed);

		vec2 noiseTexOffset = vec2(5.0/64.0, 1.0/64.0); 
		float caustics = texture2D(texture0, fract(cauLayerCoord_0)*0.015625 + noiseTexOffset).r;
		caustics += texture(texture0, fract(cauLayerCoord_1)*0.015625 + noiseTexOffset).r;
		
		
		caustics = clamp(caustics, 0.0, 2.0);
		if(caustics > 1.0){
			caustics = 2.0 - caustics;
		}
		float cauHardness = 2.0;
		float cauStrength = 0.8;
		caustics = pow(caustics * cauStrength * (0.2 + length(FOG_COLOR.rgb)) , cauHardness);

		return caustics;
    }
		



/*
    highp vec2 parallax(highp vec2 uv, highp vec3 viewDir){
        
        highp vec3 n = vec3(0.0, 1.0, 0.0);
        highp vec3 t = vec3(0.0, 0.0, 1.0);
        highp vec3 b = vec3(1.0, 0.0, 0.0);

        highp mat3 tbn = transpose(mat3(t, b, n));

        viewDir = tbn * viewDir;

        highp float height_scale = 0.01;

        //highp float height = texture2D(TEXTURE_0, uv).b;
        highp float height = 0.5;
        highp vec2 p = viewDir.xy / viewDir.z * (height * height_scale);

        //return uv;
        return uv - p;
    }
*/

	
	/////////////////////////////////////////////some experiments with TBN calculation ///////////////////////////////////////////////
	//highp vec2 duv1 = dFdx(uv0);
	//highp vec2 duv2 = dFdy(uv0);

	//highp vec3 dp2perp = cross(dp2, initNormalColor);
	//highp vec3 dp1perp = cross(initNormalColor, dp1);

	//highp vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
	//highp vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);

	//highp float invmax = inversesqrt(max(dot(T,T), dot(B,B)));
	
	//highp mat3 tbn = mat3(T, B, initNormalColor);

	//normalMap.rgb = normalMap.rgb * 2.0 - 1.0;
	
	//normalColor.rgb = tbn * normalMap.rgb;





	//highp vec3 q1 = dFdx(-position.xyz);
	//highp vec3 q2 = dFdy(-position.xyz);

	//highp vec2 st1 = dFdx(uv0);
	//highp vec2 st2 = dFdy(uv0);

	//highp vec3 T = normalize(q1*st2.t - q2*st1.t);
	//highp vec3 B = normalize(-q1*st2.s + q2*st1.s);

	//highp mat3 tbn = mat3(T, B, initNormalColor);

	//normalColor.rgb = normalColor.rgb * 2.0 - 1.0;

	//normalColor.rgb = normalMap.rgb * tbn;



	//highp vec3 t = normalize(dFdx(position.xyz));
	//highp vec3 b = normalize(dFdy(position.xyz));
	//highp vec3 n = normalize(cross(t, b));

	//highp mat3 tbn = mat3(t, b, n);

	//normalColor.rgb = normalize(normalMap.rgb * tbn);
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


