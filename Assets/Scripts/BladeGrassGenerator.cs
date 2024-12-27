using System.Collections.Generic;
using UnityEngine;

struct TerrainChunk 
{
    public Vector3 centroid;
    public Vector3 bottomLeftCornorPt;
    public int width;

    public TerrainChunk(Vector3 _centroid, Vector3 _bottomLeftCorner, int _width)
    { 
        centroid = _centroid;
        bottomLeftCornorPt = _bottomLeftCorner;
        width = _width;
    }
}

[System.Serializable]
public struct Blade
{
    public Vector3 position;
    public float windOffset;
}

public class BladeGrassGenerator : MonoBehaviour
{
    public Camera mainCam;
    [Header("Terrain Properties")]
    public MapGenerator mapGenerator;
    public GameObject terrain;
    public Texture2D heightMap;
    //public float heightMultiplier;
    //public float heightMapScale;

    // For now terrainChunkWidth will be the same as the terrain size
    // It will be way faster in one compute shader calculation
    //public int terrainChunkWidth = 40;   // Single terrain chunk size
    private int terrainChunkWidth;

    private List<TerrainChunk> terrainList;

    [Header("Blade Grass Properties")]
    public int dimension;
    private Vector2 offset;
    public float height;
    public float curveOffset;
    public float sideOffsetAmount;
    public Texture windTex;

    [Header("Instancing")]
    public Mesh mesh;
    public Shader shader;
    public ComputeShader computeShader;

    [SerializeField]
    private Material grassMat;

    public float shadingOffset = 1.2f;
    public float shadingParameter = 1.4f;
    public float windStrength = 1.2f;
    public float noiseOffset = -0.5f;
    public Vector3 windDirection = Vector3.one;

    private int instanceCount;
    private int[] bladeCntBufferData;
    private ComputeBuffer bladeBuffer;
    private ComputeBuffer bladeCntBuffer;
    private ComputeBuffer argsBuffer;

    [Header("Culling")]
    //public Camera renderCam;
    //public RenderTexture depthRenderTex;
    public float distanceCullingThreshold;
    public float frustumNearPlaneOffset;
    public float frustumEdgeOffset;
    public DepthTextureGenerator depthTextureGenerator;
    public float occludeHeightOffset;

    [Header("Debugging")]
    public int numGrassRendered = 0;

    private Vector3 camPosInWorldSpace;

    // Start is called before the first frame update
    void Start()
    {
        // Terrain calculation
        Vector3 terrainBounds = terrain.GetComponent<MeshRenderer>().bounds.size;
        terrainChunkWidth = (int)terrainBounds.x;       // TEMP
        int numOfChunkOnEachSide = (int)terrainBounds.x / terrainChunkWidth;
        int terrainSideSize = numOfChunkOnEachSide * terrainChunkWidth;
        int totalChunksNumber = numOfChunkOnEachSide * numOfChunkOnEachSide;

        Vector3 initialCenterPos = Vector3.zero;
        Vector3 startBottomLeftCornerPos = initialCenterPos - new Vector3(terrainSideSize / 2, 0.0f, terrainSideSize / 2);

        // Initialize terrain list
        terrainList = new List<TerrainChunk>();

        // Add terrains into the list
        for (int i = 0; i < numOfChunkOnEachSide; i++)
        {
            for (int j = 0; j < numOfChunkOnEachSide; j++)
            {
                Vector3 leftCornerPos = startBottomLeftCornerPos + new Vector3(i * terrainChunkWidth, 0.0f, j * terrainChunkWidth);
                Vector3 centerPos = leftCornerPos + new Vector3(terrainChunkWidth / 2, 0.0f, terrainChunkWidth / 2);

                TerrainChunk chunk = new TerrainChunk(centerPos, leftCornerPos, terrainChunkWidth);
                terrainList.Add(chunk);
            }
        }

        // Calculate attributes for compute shader
        instanceCount = dimension * dimension * totalChunksNumber;
        //Vector3 bounds = GetComponent<MeshRenderer>().bounds.size;
        offset = new Vector2((float)dimension / terrainChunkWidth, (float)dimension / terrainChunkWidth);
        InitializeComputeShader();
    }

    // Update is called once per frame
    void Update()
    {
        InitializeValues();

        // For now there will be only one chunk in the chunk list
        // Since calculating one chunk is faster
        foreach (TerrainChunk chunk in terrainList)
        {
            computeShader.SetVector("_InitialPos", chunk.bottomLeftCornorPt);

            RunSimulationStep();
        }
    }

    private void LateUpdate()
    {
        grassMat.SetBuffer("_BladeBuffer", bladeBuffer);

        grassMat.SetFloat("_Height", height);
        grassMat.SetFloat("_Offset", curveOffset);
        grassMat.SetFloat("_SideOffsetAmount", sideOffsetAmount);
        grassMat.SetFloat("_ShadingOffset", shadingOffset);
        grassMat.SetFloat("_ShadingParameter", shadingParameter);

        grassMat.SetFloat("_WindSpeed", windStrength);
        grassMat.SetVector("_WindDirection", windDirection);
        grassMat.SetTexture("_MainTex", windTex);
        grassMat.SetFloat("_NoiseOffset", noiseOffset);

        Graphics.DrawMeshInstancedIndirect(mesh, 0, grassMat, new Bounds(Vector3.zero, new Vector3(1000, 1000, 1000)), argsBuffer);
    }

    private void InitializeComputeShader()
    {
        // Initialize buffers
        bladeBuffer = new ComputeBuffer(instanceCount, sizeof(float) * 4, ComputeBufferType.Append);
        bladeCntBuffer = new ComputeBuffer(1, sizeof(int), ComputeBufferType.Raw);
        argsBuffer = new ComputeBuffer(5, sizeof(int), ComputeBufferType.IndirectArguments);
        bladeCntBufferData = new int[1];

        // Set compute buffers to compute shader
        computeShader.SetBuffer(0, "_BladeGrassBuffer", bladeBuffer);
        computeShader.SetBuffer(0, "_BladeGrassCntBuffer", bladeCntBuffer);
        computeShader.SetBuffer(1, "_BladeGrassCntBuffer", bladeCntBuffer);
        computeShader.SetBuffer(1, "_BladeGrassArgsBuffer", argsBuffer);

        // Run simulation step
        computeShader.SetInt("_Dimension", dimension);
        computeShader.SetVector("_PlacementOffset", offset);
        computeShader.SetInt("_MeshInsanceIndex", (int)mesh.GetIndexCount(0));

        // Create new material for gpu instancing
        //mat = new Material(shader);
        grassMat.SetBuffer("_BladeBuffer", bladeBuffer);
    }

    private void RunSimulationStep()
    {
        // Initialize data
        InitializeValues();

        // Get the updated camera position in world space
        camPosInWorldSpace = mainCam.transform.position;

        // Get camera GPU adjuested clip space
        Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(mainCam.projectionMatrix, false);
        Matrix4x4 adjuestedClippingMatrix = projectionMatrix * mainCam.worldToCameraMatrix;

        computeShader.SetVector("_CamPosInWorldSpace", camPosInWorldSpace);
        computeShader.SetMatrix("_CamClippingMatrix", adjuestedClippingMatrix);
        computeShader.SetFloat("_DistanceCullingThreshold", distanceCullingThreshold);
        computeShader.SetFloat("_NearPlaneOffset", frustumNearPlaneOffset);
        computeShader.SetFloat("_EdgeFrustumCullingOffset", frustumEdgeOffset);
        computeShader.SetFloat("_HeightMultiplier", mapGenerator.heightMultiplier);
        computeShader.SetFloat("_HeightMapSize", mapGenerator.terrainSize);
        computeShader.SetInt("_DepthTexSize", depthTextureGenerator.GetTextureDimension());
        computeShader.SetFloat("_OccludHeightOffset", occludeHeightOffset);
        
        computeShader.SetTexture(0, "WindTex", windTex);
        computeShader.SetTexture(0, "HeightTex", heightMap);
        computeShader.SetTexture(0, "DepthTex", depthTextureGenerator.renderTex);

        computeShader.SetVector("_Time", Shader.GetGlobalVector("_Time"));

        computeShader.Dispatch(0, Mathf.CeilToInt(dimension / 8), Mathf.CeilToInt(dimension / 8), 1);
        computeShader.Dispatch(1, 1, 1, 1);

        // Update count number
        bladeCntBuffer.GetData(bladeCntBufferData);
        numGrassRendered = bladeCntBufferData[0];
    }

    private void InitializeValues()
    {
        bladeBuffer.SetCounterValue(0);

        int[] cnt = new int[1] { 0 };
        bladeCntBuffer.SetData(cnt);

        int[] argsBufferData = new int[5] { 0, 0, 0, 0, 0 };
        argsBuffer.SetData(argsBufferData);
    }

    private void ReleaseBuffer(ComputeBuffer buffer)
    {
        if (buffer != null)
        { 
            buffer.Release();
        }
    }

    private void ReleaseBuffers()
    { 
        ReleaseBuffer(bladeBuffer);
        ReleaseBuffer(bladeCntBuffer);
        ReleaseBuffer(argsBuffer);
    }

    private void OnDestroy()
    {
        ReleaseBuffers();
    }
}
