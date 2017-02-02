package st.domain.ggviario.secret.references;

import android.graphics.drawable.Drawable;
import android.util.Log;


import st.domain.ggviario.secret.R;
import st.domain.support.android.util.ShapDrawableBuilder;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by Daniel Costa on 8/14/16.
 * User cumputer: xdata
 */
public class RColors
{
    public static final String AMBER = "AMBER";
    public static final String BLUE = "BLUE";
    public static final String BLUE_GREY = "BLUE_GREY";
    public static final String BROWN = "BROWN";
    public static final String CYAN = "CYAN";
    public static final String DEEP_ORANGE = "DEEP_ORANGE";
    public static final String GREEN = "GREEN";
    public static final String GREY = "GREY";
    public static final String DEEP_PURPLE = "DEEP_PURPLE";
    public static final String INDIGO = "INDIGO";
    public static final String LIGHT_GREEN = "LIGHT_GREEN";
    public static final String LIGHT = "LIGHT";
    public static final String LIME = "LIME";
    public static final String ORANGE = "ORANGE";
    public static final String PINK = "PINK";
    public static final String PURPLE = "PURPLE";
    public static final String RED = "RED";
    public static final String TEAL = "TEAL";
    public static final String YELLOW = "YELLOW";


    public static final int SECTOR_COLORS[] = {
            R.color.md_amber_500,
            R.color.md_cyan_500,
            R.color.md_yellow_500,
            R.color.md_pink_500,
            R.color.md_deep_purple_500,
            R.color.md_green_500,
            R.color.md_blue_grey_500,
            R.color.md_lime_500,
            R.color.md_light_blue_500,
            R.color.md_red_500,
            R.color.md_purple_500,
            R.color.md_grey_500,
            R.color.md_indigo_500,
            R.color.md_light_green_500,
    };



    public static final Integer [] AMBER_COLORS = {
            //Amber colors
            R.color.md_amber_50,
            R.color.md_amber_100,
            R.color.md_amber_200,
            R.color.md_amber_300,
            R.color.md_amber_400,
            R.color.md_amber_500,
            R.color.md_amber_600,
            R.color.md_amber_700,
            R.color.md_amber_800,
            R.color.md_amber_900,
            R.color.md_amber_A100,
            R.color.md_amber_A200,
            R.color.md_amber_A400,
            R.color.md_amber_A700,
    };

    public static final Integer [] BLUE_COLORS ={
            //Blue colors
            R.color.md_blue_50,
            R.color.md_blue_100,
            R.color.md_blue_200,
            R.color.md_blue_300,
            R.color.md_blue_400,
            R.color.md_blue_500,
            R.color.md_blue_600,
            R.color.md_blue_700,
            R.color.md_blue_800,
            R.color.md_blue_900,
            R.color.md_blue_A100,
            R.color.md_blue_A200,
            R.color.md_blue_A400,
            R.color.md_blue_A700
    };


    public static  final Integer [] BLUE_GREY_COLORS = {
            //Grey colors
            R.color.md_blue_grey_50,
            R.color.md_blue_grey_100,
            R.color.md_blue_grey_200,
            R.color.md_blue_grey_300,
            R.color.md_blue_grey_400,
            R.color.md_blue_grey_500,
            R.color.md_blue_grey_600,
            R.color.md_blue_grey_700,
            R.color.md_blue_grey_800,
            R.color.md_blue_grey_900
    };

    public static final Integer [] BROWN_COLORS = {
            //Brown colors
            R.color.md_brown_50,
            R.color.md_brown_100,
            R.color.md_brown_200,
            R.color.md_brown_300,
            R.color.md_brown_400,
            R.color.md_brown_500,
            R.color.md_brown_700,
            R.color.md_brown_800,
            R.color.md_brown_900
    };

    public static  final Integer [] CYAN_COLORS={
            //Cyan colors
            R.color.md_cyan_50, //E0F7FA</color>
            R.color.md_cyan_100,
            R.color.md_cyan_200,
            R.color.md_cyan_300,
            R.color.md_cyan_400, //26C6DA</color>
            R.color.md_cyan_500, //00BCD4</color>
            R.color.md_cyan_600, //00ACC1</color>
            R.color.md_cyan_700, //0097A7</color>
            R.color.md_cyan_800, //00838F</color>
            R.color.md_cyan_900, //006064</color>
            R.color.md_cyan_A100, //84FFFF</color>
            R.color.md_cyan_A200, //18FFFF</color>
            R.color.md_cyan_A400, //00E5FF</color>
            R.color.md_cyan_A700, //00B8D4</color>
    };


    public static  Integer [] DEEP_ORANGE_COLORS ={
            //Deep Orange color
            R.color.md_deep_orange_50, //FBE9E7</color>
            R.color.md_deep_orange_100, //FFCCBC</color>
            R.color.md_deep_orange_200, //FFAB91</color>
            R.color.md_deep_orange_300, //FF8A65</color>
            R.color.md_deep_orange_400, //FF7043</color>
            R.color.md_deep_orange_500, //FF5722</color>
            R.color.md_deep_orange_600, //F4511E</color>
            R.color.md_deep_orange_700, //E64A19</color>
            R.color.md_deep_orange_800, //D84315</color>
            R.color.md_deep_orange_900, //BF360C</color>
            R.color.md_deep_orange_A100, //FF9E80</color>
            R.color.md_deep_orange_A200, //FF6E40</color>
            R.color.md_deep_orange_A400, //FF3D00</color>
            R.color.md_deep_orange_A700, //DD2C00</color>
    };

    public static  final  Integer [] DEEP_PURPLE_COLOR ={
            //purple color
            R.color.md_deep_purple_50, //EDE7F6</color>
            R.color.md_deep_purple_100, //D1C4E9</color>
            R.color.md_deep_purple_200, //B39DDB</color>
            R.color.md_deep_purple_300, //9575CD</color>
            R.color.md_deep_purple_400, //7E57C2</color>
            R.color.md_deep_purple_500, //673AB7</color>
            R.color.md_deep_purple_600, //5E35B1</color>
            R.color.md_deep_purple_700, //512DA8</color>
            R.color.md_deep_purple_800, //4527A0</color>
            R.color.md_deep_purple_900, //311B92</color>
            R.color.md_deep_purple_A100, //B388FF</color>
            R.color.md_deep_purple_A200, //7C4DFF</color>
            R.color.md_deep_purple_A400, //651FFF</color>
            R.color.md_deep_purple_A700, //6200EA</color>
    };

    public static  Integer [] GREEN_COLORS ={
            //Green color
            R.color.md_green_50, //E8F5E9</color>
            R.color.md_green_100, //C8E6C9</color>
            R.color.md_green_200, //A5D6A7</color>
            R.color.md_green_300, //81C784</color>
            R.color.md_green_400, //66BB6A</color>
            R.color.md_green_500, //4CAF50</color>
            R.color.md_green_600, //43A047</color>
            R.color.md_green_700, //388E3C</color>
            R.color.md_green_800, //2E7D32</color>
            R.color.md_green_900, //1B5E20</color>
            R.color.md_green_A100, //B9F6CA</color>
            R.color.md_green_A200, //69F0AE</color>
            R.color.md_green_A400, //00E676</color>
            R.color.md_green_A700, //00C853</color>
    } ;

    public static  final Integer[] GREY_COLORS = {
            //Grey color
            R.color.md_grey_50, //FAFAFA</color>
            R.color.md_grey_100, //F5F5F5</color>
            R.color.md_grey_200, //EEEEEE</color>
            R.color.md_grey_300, //E0E0E0</color>
            R.color.md_grey_400, //BDBDBD</color>
            R.color.md_grey_500, //9E9E9E</color>
            R.color.md_grey_600, //757575</color>
            R.color.md_grey_700, //616161</color>
            R.color.md_grey_800, //424242</color>
            R.color.md_grey_900, //212121</color>
            R.color.md_grey_850, //303030</color>
    };

    public static final Integer INDIGO_COLORS [] = {
            //Indigo color
            R.color.md_indigo_50, //E8EAF6</color>
            R.color.md_indigo_100, //C5CAE9</color>
            R.color.md_indigo_200, //9FA8DA</color>
            R.color.md_indigo_300, //7986CB</color>
            R.color.md_indigo_400, //5C6BC0</color>
            R.color.md_indigo_500, //3F51B5</color>
            R.color.md_indigo_600, //3949AB</color>
            R.color.md_indigo_700, //303F9F</color>
            R.color.md_indigo_800, //283593</color>
            R.color.md_indigo_900, //1A237E</color>
            R.color.md_indigo_A100, //8C9EFF</color>
            R.color.md_indigo_A200, //536DFE</color>
            R.color.md_indigo_A400, //3D5AFE</color>
            R.color.md_indigo_A700, //304FFE</color>
    };


    public static  final Integer LIGNT_COLORS [] = {
            //Light color
            R.color.md_light_blue_50, //E1F5FE</color>
            R.color.md_light_blue_100, //B3E5FC</color>
            R.color.md_light_blue_200, //81D4FA</color>
            R.color.md_light_blue_300, //4FC3F7</color>
            R.color.md_light_blue_400, //29B6F6</color>
            R.color.md_light_blue_500, //03A9F4</color>
            R.color.md_light_blue_600, //039BE5</color>
            R.color.md_light_blue_700, //0288D1</color>
            R.color.md_light_blue_800, //0277BD</color>
            R.color.md_light_blue_900, //01579B</color>
            R.color.md_light_blue_A100, //80D8FF</color>
            R.color.md_light_blue_A200, //40C4FF</color>
            R.color.md_light_blue_A400, //00B0FF</color>
            R.color.md_light_blue_A700, //0091EA</color>
    };

    public static final  Integer LIGHT_GREEN_COLORS [] = {
            //Green color
            R.color.md_light_green_50, //F1F8E9</color>
            R.color.md_light_green_100, //DCEDC8</color>
            R.color.md_light_green_200, //C5E1A5</color>
            R.color.md_light_green_300, //AED581</color>
            R.color.md_light_green_400, //9CCC65</color>
            R.color.md_light_green_500, //8BC34A</color>
            R.color.md_light_green_600, //7CB342</color>
            R.color.md_light_green_700, //689F38</color>
            R.color.md_light_green_800, //558B2F</color>
            R.color.md_light_green_900, //33691E</color>
            R.color.md_light_green_A100, //CCFF90</color>
            R.color.md_light_green_A200, //B2FF59</color>
            R.color.md_light_green_A400, //76FF03</color>
            R.color.md_light_green_A700, //64DD17</color>
    };

    public static  final Integer [] LIME_COLORS =  {
            //Lime color
            R.color.md_lime_50, //F9FBE7</color>
            R.color.md_lime_100, //F0F4C3</color>
            R.color.md_lime_200, //E6EE9C</color>
            R.color.md_lime_300, //DCE775</color>
            R.color.md_lime_400, //D4E157</color>
            R.color.md_lime_500, //CDDC39</color>
            R.color.md_lime_600, //C0CA33</color>
            R.color.md_lime_700, //AFB42B</color>
            R.color.md_lime_800, //9E9D24</color>
            R.color.md_lime_900, //827717</color>
            R.color.md_lime_A100, //F4FF81</color>
            R.color.md_lime_A200, //EEFF41</color>
            R.color.md_lime_A400, //C6FF00</color>
            R.color.md_lime_A700, //AEEA00</color>
    };

    public static  final  Integer [] ORANGE_COLORS = {
            //Orange color
            R.color.md_orange_50, //FFF3E0</color>
            R.color.md_orange_100, //FFE0B2</color>
            R.color.md_orange_200, //FFCC80</color>
            R.color.md_orange_300, //FFB74D</color>
            R.color.md_orange_400, //FFA726</color>
            R.color.md_orange_500, //FF9800</color>
            R.color.md_orange_600, //FB8C00</color>
            R.color.md_orange_700, //F57C00</color>
            R.color.md_orange_800, //EF6C00</color>
            R.color.md_orange_900, //E65100</color>
            R.color.md_orange_A100, //FFD180</color>
            R.color.md_orange_A200, //FFAB40</color>
            R.color.md_orange_A400, //FF9100</color>
            R.color.md_orange_A700, //FF6D00</color>
    };

    public static final Integer [] PINK_COLORS = {
            //Pink color
            R.color.md_pink_50, //FCE4EC</color>
            R.color.md_pink_100, //F8BBD0</color>
            R.color.md_pink_200, //F48FB1</color>
            R.color.md_pink_300, //F06292</color>
            R.color.md_pink_400, //EC407A</color>
            R.color.md_pink_500, //E91E63</color>
            R.color.md_pink_600, //D81B60</color>
            R.color.md_pink_700, //C2185B</color>
            R.color.md_pink_800, //AD1457</color>
            R.color.md_pink_900, //880E4F</color>
            R.color.md_pink_A100, //FF80AB</color>
            R.color.md_pink_A200, //FF4081</color>
            R.color.md_pink_A400, //F50057</color>
            R.color.md_pink_A700, //C51162</color>
    };

    public static final Integer [] PURPLE_COLORS = {
            //Purple color
            R.color.md_purple_50, //F3E5F5</color>
            R.color.md_purple_100, //E1BEE7</color>
            R.color.md_purple_200, //CE93D8</color>
            R.color.md_purple_300, //BA68C8</color>
            R.color.md_purple_400, //AB47BC</color>
            R.color.md_purple_500, //9C27B0</color>
            R.color.md_purple_600, //8E24AA</color>
            R.color.md_purple_700, //7B1FA2</color>
            R.color.md_purple_800, //6A1B9A</color>
            R.color.md_purple_900, //4A148C</color>
            R.color.md_purple_A100, //EA80FC</color>
            R.color.md_purple_A200, //E040FB</color>
            R.color.md_purple_A400, //D500F9</color>
            R.color.md_purple_A700, //AA00FF</color>
    };

    public static  final  Integer [] RED_COLORS = {
            //Red color
            R.color.md_red_50, //FFEBEE</color>
            R.color.md_red_100, //FFCDD2</color>
            R.color.md_red_200, //EF9A9A</color>
            R.color.md_red_300, //E57373</color>
            R.color.md_red_400, //EF5350</color>
            R.color.md_red_500, //F44336</color>
            R.color.md_red_600, //E53935</color>
            R.color.md_red_700, //D32F2F</color>
            R.color.md_red_800, //C62828</color>
            R.color.md_red_900, //B71C1C</color>
            R.color.md_red_A100, //FF8A80</color>
            R.color.md_red_A200, //FF5252</color>
            R.color.md_red_A400, //FF1744</color>
            R.color.md_red_A700, //D50000</color>
    };

    public static final Integer [] TEAL_COLORS = {
            //Teal color
            R.color.md_teal_50, //E0F2F1</color>
            R.color.md_teal_100, //B2DFDB</color>
            R.color.md_teal_200, //80CBC4</color>
            R.color.md_teal_300, //4DB6AC</color>
            R.color.md_teal_400, //26A69A</color>
            R.color.md_teal_500, //009688</color>
            R.color.md_teal_600, //00897B</color>
            R.color.md_teal_700, //00796B</color>
            R.color.md_teal_800, //00695C</color>
            R.color.md_teal_900, //004D40</color>
            R.color.md_teal_A100, //A7FFEB</color>
            R.color.md_teal_A200, //64FFDA</color>
            R.color.md_teal_A400, //1DE9B6</color>
            R.color.md_teal_A700, //00BFA5</color>
    };

    public static  final  Integer [] YELLOW_COLORS = {
            //Teal color
            R.color.md_yellow_50, //FFFDE7</color>
            R.color.md_yellow_100, //FFF9C4</color>
            R.color.md_yellow_200, //FFF59D</color>
            R.color.md_yellow_300, //FFF176</color>
            R.color.md_yellow_400, //FFEE58</color>
            R.color.md_yellow_500, //FFEB3B</color>
            R.color.md_yellow_600, //FDD835</color>
            R.color.md_yellow_700, //FBC02D</color>
            R.color.md_yellow_800, //F9A825</color>
            R.color.md_yellow_900, //F57F17</color>
            R.color.md_yellow_A100, //FFFF8D</color>
            R.color.md_yellow_A200, //FFFF00</color>
            R.color.md_yellow_A400, //FFEA00</color>
            R.color.md_yellow_A700 //FFD600</color>
    };

    private static final HashMap<Integer, Integer> MAP_INDEX = new HashMap<>();
    static {
        MAP_INDEX.put(50, 0);
        MAP_INDEX.put(100, 1);
        MAP_INDEX.put(200, 2);
        MAP_INDEX.put(300, 3);
        MAP_INDEX.put(400, 4);
        MAP_INDEX.put(500, 5);
        MAP_INDEX.put(600, 6);
        MAP_INDEX.put(700, 7);
        MAP_INDEX.put(800, 8);
        MAP_INDEX.put(900, 9);
    }

    private static HashMap<String, Integer[]> MAP_COLORS = new HashMap<String, Integer[]>();
    static
    {
        MAP_COLORS.put(AMBER, AMBER_COLORS);
        MAP_COLORS.put(BLUE, BLUE_COLORS);
        MAP_COLORS.put(BLUE_GREY, BLUE_GREY_COLORS);
        MAP_COLORS.put(BROWN, BROWN_COLORS);
        MAP_COLORS.put(CYAN, CYAN_COLORS);
        MAP_COLORS.put(DEEP_ORANGE, DEEP_ORANGE_COLORS);
        MAP_COLORS.put(GREEN, GREEN_COLORS);
        MAP_COLORS.put(GREY, GREY_COLORS);
        MAP_COLORS.put(DEEP_PURPLE, DEEP_PURPLE_COLOR);
        MAP_COLORS.put(INDIGO, INDIGO_COLORS);
        MAP_COLORS.put(LIGHT_GREEN, LIGHT_GREEN_COLORS);
        MAP_COLORS.put(LIGHT, LIGNT_COLORS);
        MAP_COLORS.put(LIME, LIME_COLORS);
        MAP_COLORS.put(ORANGE, ORANGE_COLORS);
        MAP_COLORS.put(PINK, PINK_COLORS);
        MAP_COLORS.put(PURPLE, PURPLE_COLORS);
        MAP_COLORS.put(RED, RED_COLORS);
        MAP_COLORS.put(TEAL, TEAL_COLORS);
        MAP_COLORS.put(YELLOW, YELLOW_COLORS);
    }


    public static int switchColor(int shapKey, int level)
    {
        int [] allColor = getAllColorOfLevel(level);

        int indexShap = shapKey % allColor.length;
        try
        {
            return allColor[indexShap];
        }
        catch (Exception ex)
        {
            Log.e("DBA:APP.TEST", RColors.class.getSimpleName()+"-> "+ex.getMessage());
            return R.drawable.shap_oval_primary;
        }
    }

    public static int switchColor(int [] colors, int key) {
        int indexColor = key % colors.length;
        return colors[key];
    }

    /**
     * Get cor a by do level
     * @param colorName the name of color
     * @param level the level of color
     * @return -1 if color not found
     */
    public static int getColor(String colorName, int level)
    {
        try {
            if(!MAP_INDEX.containsKey(level)) return -1;
            return MAP_COLORS.get(colorName)[MAP_INDEX.get(level)];
        }catch (Exception ex)
        {
            return -1;
        }
    }


    /**
     * Get the color of one level
     * @return null if level do no exist
     */
    public static int [] getAllColorOfLevel(int levelColor)
    {
        if (!MAP_INDEX.containsKey(levelColor)) return null;
        int colorsOfLevel [] = new int[MAP_COLORS.size()];
        int iCount = 0;
        for(Map.Entry<String, Integer[]> item: MAP_COLORS.entrySet())
            colorsOfLevel[iCount ++] = item.getValue()[MAP_INDEX.get(levelColor)];
        return colorsOfLevel;
    }

    /**
     * Randon to chose one element into array
     * @param values the array to randon
     * @return null if any error value is null jor empty
     */
    public static Object randonIn(Object ... values)
    {
        if(values == null || values.length == 0) return  null;
        int randon = (int) (Math.random() * values.length);
        return values[randon];
    }
}

