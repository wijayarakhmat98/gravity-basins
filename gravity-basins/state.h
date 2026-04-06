#ifndef state_h
#define state_h

float2 screen_to_world(float2 position, float2 resolution, float2 origin, float scale);
float2 world_to_screen(float2 position, float2 resolution, float2 origin, float scale);

#endif
