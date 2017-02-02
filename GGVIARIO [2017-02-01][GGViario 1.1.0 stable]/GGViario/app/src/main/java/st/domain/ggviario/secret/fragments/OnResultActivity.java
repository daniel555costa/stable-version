package st.domain.ggviario.secret.fragments;

import android.content.Context;
import android.content.Intent;

/**
 *
 * Created by dchost on 30/01/17.
 */

public interface OnResultActivity {

    boolean onResultActivity(int requestCode, int resultCode, Intent data, Context context);
}
