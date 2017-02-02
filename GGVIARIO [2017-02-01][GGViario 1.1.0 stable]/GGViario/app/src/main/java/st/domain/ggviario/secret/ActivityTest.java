package st.domain.ggviario.secret;

import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.view.View;

import st.domain.support.android.util.ShapDrawableBuilder;

/**
 *
 * Created by dchost on 27/01/17.
 */

public class ActivityTest extends AppCompatActivity {

    View view;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.test);
        this.view = this.findViewById(R.id.test_back);

        ShapDrawableBuilder drawableBuilder = new ShapDrawableBuilder(this);

        drawableBuilder.shap(ShapDrawableBuilder.Shap.OVAL)
                .stroke(4, R.color.md_blue_500)
                .radius(2)
                .solidColor(R.color.colorAccent);

        this.view.setBackground(drawableBuilder.build());

    }

    // adb push /home/dchost/workspace/GGViarioL/app/build/outputs/apk/app-debug.apk /data/local/tmp/st.domain.ggviario.secret
    // $ adb shell pm install -r "/data/local/tmp/st.domain.ggviario.secret"
    // adb shell am start -n "st.domain.ggviario.secret/st.domain.ggviario.secret.ActivityTest" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER



    public static void customView(View v, int backgroundColor, int borderColor)
    {
        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.OVAL);


        shape.setCornerRadii(new float[] { 8, 8, 8, 8, 0, 0, 0, 0 });
        shape.setColor(backgroundColor);
        shape.setStroke(3, borderColor);
        v.setBackgroundDrawable(shape);
    }

    /**
     TAEG

     <shape xmlns:android="http://schemas.android.com/apk/res/android"
     android:shape="oval">
     <solid android:color="@color/md_amber_500"/>
     </shape>
     */

}
