using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

public class NPRShaderGUI : ShaderGUI
{
    Material target;

    //�����з������ܷ�������������
    MaterialEditor materialEditor;
    MaterialProperty[] properties;

    //��һ�������Ƕ�MaterialEditor�����á��ö������ǰѡ�����ʵļ�������ڶ��������ǰ����ò������Ե�����
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //����Щ���Ը�ֵ
        this.target = materialEditor.target as Material;
        this.materialEditor = materialEditor;
        this.properties = properties;
        DoMain();//����ͼ����
    }

    void DoMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);
        MaterialProperty mainTex = FindProperty("_MainTex");
        materialEditor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo(RGB)"), mainTex, FindProperty("_MainColor"));//��������󶨵����ӻ��༭������
        materialEditor.TextureScaleOffsetProperty(mainTex);//��������ñ༭����ʾTiling��Offset����
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
        EditorGUI.BeginChangeCheck();//��鷽���Ƿ��и���
        materialEditor.TexturePropertySingleLine(
            MakeLabel(map, "FaceShadow"), map,
            map.textureValue ? FindProperty("_FaceShadowOffset") : null//����ͼ��ʱ�����ػ���
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
            SetKeyword("_FACESHADOW_MAP", map.textureValue);//���沿��Ӱ����Ϊ�ؼ���
        }
    }

    void DoLightMapShadow()
    {
        GUILayout.Space(10);
        GUILayout.Label("LightShadow", EditorStyles.boldLabel);
        MaterialProperty map = FindProperty("_LightShadowMap");
        materialEditor.TexturePropertySingleLine(MakeLabel(map, "LightShadow"), map);
    }


    //���ߺ�������
    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    static GUIContent staticLabel = new GUIContent();//�滻�ı��͹�����ʾ����
    static GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {//ֱ�Ӵ������еõ��ı�����ʾ
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword(string keyword, bool state)
    {
        if (state)
        {//foreach�������е�Ŀ����ʣ���Ȼֻ���е�һ����������Ӧ�Ĳ���
            foreach (Material m in materialEditor.targets)
            {
                m.EnableKeyword(keyword);//ʹ�ø÷������ؼ�����ӵ���ɫ����
            }
        }
        else
        {
            foreach (Material m in materialEditor.targets)
            {
                m.DisableKeyword(keyword);//ʹ�ø÷������ؼ�����ӵ���ɫ����
            }
        }
    }

    bool IsKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    void RecordAction(string label)
    {
        materialEditor.RegisterPropertyChangeUndo(label);//֧�ֳ�������
    }
}