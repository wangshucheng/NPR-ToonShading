using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class NPRShaderGUI : ShaderGUI
{
    Material target;

    //让所有方法都能访问这两个属性
    MaterialEditor materialEditor;
    MaterialProperty[] properties;

    //第一个参数是对MaterialEditor的引用。该对象管理当前选定材质的检查器。第二个属性是包含该材质属性的数组
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //给这些属性赋值
        this.target = materialEditor.target as Material;
        this.materialEditor = materialEditor;
        this.properties = properties;
        DoMain();//主帖图部分
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty mainTex = FindProperty("_MainTex");
        materialEditor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo(RGB)"), mainTex, FindProperty("_MainColor"));//将这组件绑定到可视化编辑器上面
        materialEditor.TextureScaleOffsetProperty(mainTex);//这个函数让编辑器显示Tiling和Offset属性
        DoRamp();
        DoMetal();
        DoLightMapShadow();
        DoFaceShadow();

        DoSpecular();
        DoShadow();
        DoRimColor();
        DoOutLine();
    }

    void DoRamp()
    {
        GUILayout.Space(10);
        GUILayout.Label("Ramp Maps", EditorStyles.boldLabel);
        MaterialProperty RampMap = FindProperty("_RampTex");
        materialEditor.TexturePropertySingleLine(MakeLabel(RampMap, "RampMap"), RampMap);
    }

    void DoMetal()
    {
        GUILayout.Space(10);
        GUILayout.Label("Metal Maps", EditorStyles.boldLabel);
        MaterialProperty MetalMaps = FindProperty("_MetalTex");
        materialEditor.TexturePropertySingleLine(MakeLabel(MetalMaps, "MetalMap"), MetalMaps);
    }

    void DoRimColor()
    {
        GUILayout.Space(10);
        GUILayout.Label("Rim Control", EditorStyles.boldLabel);
        // MaterialProperty RimColor = FindProperty("_RimColor");
        // materialEditor.ColorProperty(RimColor,"RimColor");

        // MaterialProperty RimMax = FindProperty("_RimMax");
        // materialEditor.RangeProperty(RimMax,"RimMax");

        // MaterialProperty RimMin = FindProperty("_RimMin");
        // materialEditor.RangeProperty(RimMin,"RimMin");

        MaterialProperty RimColor = FindProperty("_RimColor");
        materialEditor.ColorProperty(RimColor, "RimColor");

        MaterialProperty OffsetMul = FindProperty("_OffsetMul");
        materialEditor.RangeProperty(OffsetMul, "_RimWidth");

        MaterialProperty Threshold = FindProperty("_Threshold");
        materialEditor.RangeProperty(Threshold, "_Threshold");
    }

    void DoOutLine()
    {
        GUILayout.Space(10);
        GUILayout.Label("OutLine Control", EditorStyles.boldLabel);

        MaterialProperty OutLineWidth = FindProperty("_OutLineWidth");
        materialEditor.RangeProperty(OutLineWidth, "OutLineWidth");

        MaterialProperty OutLineColor = FindProperty("_OutLineColor");
        materialEditor.ColorProperty(OutLineColor, "OutLineColor");

        MaterialProperty Factor = FindProperty("_Factor");
        materialEditor.RangeProperty(Factor, "Factor");
    }

    void DoSpecular()
    {
        GUILayout.Space(10);
        GUILayout.Label("Specular Control", EditorStyles.boldLabel);

        MaterialProperty SpecualrColor = FindProperty("_SpecularColor");
        materialEditor.ColorProperty(SpecualrColor, "SpecualrColor");

        MaterialProperty SpecularGloss = FindProperty("_SpecularGloss");
        materialEditor.RangeProperty(SpecularGloss, "SpecularGloss");

    }

    void DoShadow()
    {
        GUILayout.Space(10);
        GUILayout.Label("Shadow Control", EditorStyles.boldLabel);

        MaterialProperty ShadowColor = FindProperty("_ShadowColor");
        materialEditor.ColorProperty(ShadowColor, "ShadowColor");

        MaterialProperty ShadowRange = FindProperty("_ShadowRange");
        materialEditor.RangeProperty(ShadowRange, "ShadowRange");

        MaterialProperty ShadowSmooth = FindProperty("_ShadowSmooth");
        materialEditor.RangeProperty(ShadowSmooth, "ShadowSmooth");
    }

    void DoFaceShadow()
    {
        GUILayout.Space(10);
        GUILayout.Label("FaceShadowMap", EditorStyles.boldLabel);
        MaterialProperty map = FindProperty("_FaceShadowMap");
        EditorGUI.BeginChangeCheck();//检查方法是否有更改
        materialEditor.TexturePropertySingleLine(
            MakeLabel(map, "FaceShadow"), map,
            map.textureValue ? FindProperty("_FaceShadowOffset") : null//有贴图的时候隐藏滑块
            );
        if (map.textureValue)
        {
            MaterialProperty FaceShadowMapPow = FindProperty("_FaceShadowMapPow");
            materialEditor.RangeProperty(FaceShadowMapPow, "_FaceShadowMapPow");

            MaterialProperty WhetherFixLight = FindProperty("_IgnoreLightY");
            materialEditor.FloatProperty(WhetherFixLight, "_IgnoreLightY");
        }
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_FACESHADOW_MAP", map.textureValue);//将面部阴影定义为关键字
        }
    }

    void DoLightMapShadow()
    {
        GUILayout.Space(10);
        GUILayout.Label("LightShadow", EditorStyles.boldLabel);
        MaterialProperty map = FindProperty("_LightShadowMap");
        materialEditor.TexturePropertySingleLine(MakeLabel(map, "LightShadow"), map);
    }


    //工具函数部分
    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    static GUIContent staticLabel = new GUIContent();//替换文本和工具提示函数
    static GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {//直接从属性中得到文本和提示
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword(string keyword, bool state)
    {
        if (state)
        {//foreach遍历所有的目标材质，不然只会有第一个材质有相应的操作
            foreach (Material m in materialEditor.targets)
            {
                m.EnableKeyword(keyword);//使用该方法将关键字添加到着色器中
            }
        }
        else
        {
            foreach (Material m in materialEditor.targets)
            {
                m.DisableKeyword(keyword);//使用该方法将关键字添加到着色器中
            }
        }
    }

    bool IsKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    void RecordAction(string label)
    {
        materialEditor.RegisterPropertyChangeUndo(label);//支持撤销操作
    }
}