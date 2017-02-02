package st.domain.ggviario.secret.callbaks;

import android.app.Activity;
import android.view.MenuItem;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by Daniel Costa at 8/30/16.
 * Using user computer xdata
 */
public class BackHomeUpMenuObserver implements MenuObserver
{
    private List<OnFinishing> onFinishingList;
    private int idMenu;

    public BackHomeUpMenuObserver()
    {
        this.onFinishingList = new ArrayList<>();
        this.idMenu =  android.R.id.home;
    }

    public BackHomeUpMenuObserver setMenuId(int idMenu) {
        this.idMenu = idMenu;
        return this;
    }

    public BackHomeUpMenuObserver add(OnFinishing onFinishing) {
        this.onFinishingList.add(onFinishing);
        return this;
    }

    @Override
    public boolean accept(MenuItem menuItem, Activity activity)
    {
        for(OnFinishing onFinishing: this.onFinishingList)
                onFinishing.onFinish(activity);
        activity.finish();
        return true;
    }

    @Override
    public int getKey() {
        return  this.idMenu;
    }

    public interface OnFinishing {
        void onFinish(Activity activity);
    }
}
