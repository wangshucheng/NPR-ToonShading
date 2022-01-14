using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FragNormalShow : MonoBehaviour
{
	Material material;
	Camera camera;
	// Use this for initialization
	void Start()
	{
		material = new Material(Shader.Find("Hidden/FragNormalShow"));
		camera = GetComponent<Camera>();
	}
	void Update()
	{

		if (Input.GetMouseButton(0))
		{
			var spos = Vector2.Scale(Input.mousePosition, new Vector2(1.0f / Screen.width, 1.0f / Screen.height));
			Shader.SetGlobalVector("FragNormalMousePos", spos);
		}
	}

	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		Shader.SetGlobalMatrix("MainVP", GL.GetGPUProjectionMatrix(camera.projectionMatrix, false) * camera.worldToCameraMatrix);
		Graphics.Blit(src, dest, material);
	}

}