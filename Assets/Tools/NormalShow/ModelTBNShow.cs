using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModelTBNShow : MonoBehaviour
{
    [Range(0f, 10f)]
    public float tbnLen = 0.1f;
    [Range(0, 1000)]
    public int maxShowNum = 100;
    public bool showNormal = true;
    public bool showTangent = true;
    public bool showBiTangent = true;

    MeshFilter meshFilter;
    Mesh sharedMesh;

    Matrix4x4 localToWorld;
    Matrix4x4 localToWorldInverseTranspose;

    private void OnDrawGizmos()
    {
        meshFilter = GetComponent<MeshFilter>();
        sharedMesh = meshFilter.sharedMesh;

        localToWorld = meshFilter.transform.localToWorldMatrix;
        localToWorldInverseTranspose = localToWorld.inverse.transpose;

        Vector3[] vertices = sharedMesh.vertices;
        Vector3[] normals = sharedMesh.normals;
        Vector4[] tangents = sharedMesh.tangents;

        int tangentsLen = (tangents != null ? tangents.Length : 0);
        Vector3[] biTangents = new Vector3[tangentsLen];
        Vector3[] tangentsData = new Vector3[tangentsLen];
        for (int i = 0; i < tangentsLen; i++)
        {
            //���������� Vector4 ת Vector3
            tangentsData[i].x = tangents[i].x;
            tangentsData[i].y = tangents[i].y;
            tangentsData[i].z = tangents[i].z;
            //���㸱���� cross(��������������)*����ϵ�������
            biTangents[i] = Vector3.Cross(normals[i], tangentsData[i]) * tangents[i].w;
        }

        /*
         * localToWorld �� ����λ�� ��ģ������ϵת����������ϵ����
         * localToWorldInverseTranspose �� ���� ��ģ������ϵת����������ϵ����
         *      1��������t�͸�������b ���ڷ�������������ϵһ�� ʹ��localToWorld��localToWorldInverseTranspose����ת������������ϵ �����ͬ
         *      2��normal ����ģ���зǵȱ����ŵ���������ź󶥵�ķ�����ʹ��localToWorld����ת���Ľ������ȷ
         *      �����MΪ������t��ת������,����GΪ������n��ת������,
         *      ת�������������t2 = M*t�� ת����ķ�����n2 = G*n��ͬʱҪ�� n2 * t2 = 0
         *      ����  (G*n)' * (M*t) = 0  =>  n'*G'*M*t = 0  (n'��ʾ����n��ת��, G'��ʾ����G��ת��)
         *      ��֪ n'*t = 0(����������������ֱ)�� ��ʱ����� G'*M = I(��λ����)
         *      ���� n'*G'*M*t = n'*I*t = n'*t = 0 ����
         *      �ɵ� G'*M = I => G = (inverse(M))'
         */
        if (showNormal) DrawVectors(vertices, normals, ref localToWorld, ref localToWorldInverseTranspose, Color.red, tbnLen);
        if (showTangent) DrawVectors(vertices, tangentsData, ref localToWorld, ref localToWorld, Color.green, tbnLen);
        if (showBiTangent) DrawVectors(vertices, biTangents, ref localToWorld, ref localToWorld, Color.blue, tbnLen);
    }

    /*��ʾ����
     * vertexs ������ʼλ��
     * vectors ��������
     * vertexMatrix ������ʼλ�ô�ģ������ϵת����������ϵ����
     * vectorMatrix ���������ģ������ϵת����������ϵ����
     * color ������ɫ
     * */
    void DrawVectors(Vector3[] vertexs, Vector3[] vectors, ref Matrix4x4 vertexMatrix, ref Matrix4x4 vectorMatrix, Color color, float vectorLen)
    {
        Gizmos.color = color;
        int len = (vertexs == null || vectors == null ? 0 : vertexs.Length);
        len = Mathf.Min(len, maxShowNum);
        if (vertexs.Length != vectors.Length)
        {
            Debug.LogError("vertexs lenght not equal vectors length!!!");
            return;
        }
        for (int i = 0; i < len; i++)
        {
            Vector3 vertexData = vertexMatrix.MultiplyPoint(vertexs[i]);
            Vector3 vectorData = vectorMatrix.MultiplyVector(vectors[i]);
            vectorData.Normalize();
            Gizmos.DrawLine(vertexData, vertexData + vectorData * vectorLen);
        }
    }
}
