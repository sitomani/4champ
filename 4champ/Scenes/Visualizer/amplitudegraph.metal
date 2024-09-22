#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float factor;
};

struct ScaleIn {
    uint16_t width;
    uint16_t height;
};

vertex VertexOut vertex_main(const device int16_t *audioLeft [[buffer(0)]],
                             const device int16_t *audioRight [[buffer(1)]],
                             constant uint &frameCount [[buffer(2)]],
                             constant ScaleIn &scale [[buffer(3)]],
                             uint vertexID [[vertex_id]]) {
    VertexOut out;

    float x = float(vertexID) / float(scale.width);

    uint sampleIndex = int(x*frameCount);

    float amplitude = float((audioLeft[sampleIndex] + audioRight[sampleIndex])/2) / 32768.0;

    // smooth the path a bit if we are spreading the width
    if (scale.width > frameCount && sampleIndex < frameCount-1 && sampleIndex > 0) {
        amplitude += float((audioLeft[sampleIndex-1] + audioRight[sampleIndex-1])/2) / 32768.0 / 2.0;
        amplitude += float((audioLeft[sampleIndex+1] + audioRight[sampleIndex+1])/2) / 32768.0 / 2.0;
    }

    float maxY = 150.0 + (0.22 * (scale.height - 400.0));
    float yPortion = maxY / scale.height;

    float maxQuadHeight = 3.5;
    float multiplier = -(4*maxQuadHeight)*x*x + (4*maxQuadHeight)*x;
    float thickness = (1.5 + multiplier)/(scale.height*yPortion);
    yPortion = yPortion * (1+multiplier/20);

    if (vertexID % 2 == 0) {
        out.position = float4(x * 2.0 - 1.0, (amplitude - thickness) * yPortion, 0.0, 1.0);
    } else {
        out.position = float4(x * 2.0 - 1.0, (amplitude + thickness) * yPortion, 0.0, 1.0);
    }

    out.factor = multiplier;

    return out;
}


fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    float3 color = mix(float3(0.256,0.37,0.632), float3(1, 1, 1),  in.factor/4);
    return float4(color, 1.0);
}


