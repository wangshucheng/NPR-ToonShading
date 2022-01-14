using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class Bloom : MonoBehaviour
{
    [SerializeField] Material material;
    [SerializeField] Shader bloomShader;

    [Range(0, 4)]
    public int iterations = 3;

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;//��ȡ�������ֵ��С��Ϊ��HDR���Է�Χ��0-4

    const string m_bloomShaderID = "Custom/Bloom";

    private void Awake()
    {
        bloomShader = Shader.Find(m_bloomShaderID);
        material = new Material(bloomShader);
    }
    private void Start()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;//�򿪵�ǰ����������ͼ
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);//���Դ���һ��������
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0, material, 0);

            for (int i = 0; i < iterations; i++)
            {//��������
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);//�ͷ��Դ�
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(source, destination, material, 3);

            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}