# Grass-Rendering-With-Bezier-Curve
#### Unity Version: 2022.3.8f1 LTS

#### URP Version: 14.0.8

Grass Rendering in Unity inspired by Ghost of Tsushima GDC talk.

Features implemented:
+ Compute Shader and GPU Instancing to generate blade grass with stable FPS.
+ Wind map with vertex animation.
+ Distance culling, frustum culling and occlusion culling.
+ Procedural generated terrain mesh with height map.

## Current result
### Able to render 3200 x 3200 dimensions blade grass in 60 FPS
![land_scape_wind_animation](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/landscape_wind_animation.gif)

![wind_animation](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/wind_animation.gif)

### Culling effects
![culling_effects](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/culling_effect.gif)

## Start with 10x10 chunk and blade mesh grass
![init commit](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/blade_grass_generation_00.png)

## Use Bezier Curve to controll the shape of the grass
![Bezier curve](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/blade_grass_rendering_02.png)

## Add lighting and color to the grass
![diffuse lighting](https://github.com/harlan0103/Grass-Rendering-With-Bezier-Curve/blob/main/Outputs/blade_grass_rendering_04.png)

## Next steps:
+ LOD
+ Procedural generated blade grass

## Reference:
https://www.gdcvault.com/play/1027033/Advanced-Graphics-Summit-Procedural-Grass <br/>
https://www.youtube.com/watch?v=bp7REZBV4P4&t=403s <br/>
https://www.cg.tuwien.ac.at/research/publications/2017/JAHRMANN-2017-RRTG/JAHRMANN-2017-RRTG-draft.pdf <br/>
https://zhuanlan.zhihu.com/p/396979267 <br/>
https://www.youtube.com/watch?v=Y0Ko0kvwfgA&t=452s <br/>
