using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class PlugTangentTools
{
    [MenuItem("Tools/ģ��ƽ������д����������")]
    public static void WirteAverageNormalToTangentToos()
    {
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach (var meshFilter in meshFilters)
        {
            Mesh mesh = meshFilter.sharedMesh;
            WirteAverageNormalToTangent(mesh);
        }

        SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var skinMeshRender in skinMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            WirteAverageNormalToTangent(mesh);
        }
    }

    private static void WirteAverageNormalToTangent(Mesh mesh)
    {
        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        //Debug.Log("mesh.vertexCount:" + mesh.vertexCount);
        //Debug.Log("mesh.vertices.Length:" + mesh.vertices.Length);

        for (var j = 0; j < mesh.vertexCount; j++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
            {
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] =
                    (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
            }
        }

        var averageNormals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
        }

        var tangents = new Vector4[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
        }
        mesh.tangents = tangents;
    }
}