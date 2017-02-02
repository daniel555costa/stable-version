package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.util.Pair;

import java.util.LinkedList;
import java.util.List;

/**
 *
 * Created by dchost on 31/01/17.
 */

public class PagerAdapter extends FragmentPagerAdapter {

    private final Context context;
    List<Pair<String, Fragment>> pairList;

    public PagerAdapter(FragmentManager fragmentManager, Context context) {
        super(fragmentManager);
        this.pairList = new LinkedList<>();
        android.util.AttributeSet l;
        this.context = context;
    }

    @Override
    public int getCount() {
        return this.pairList.size();
    }

    public void addFragment(String title, Fragment fragment) {
        this.pairList.add(new Pair<>(title, fragment));
    }

    private Pair<String, Fragment> get(int index) {
        return this.pairList.get(index);
    }

    @Override
    public Fragment getItem(int index) {
        return this.get(index).second;
    }

    @Override
    public CharSequence getPageTitle(int position) {
        return String.valueOf(this.get(position).first).toUpperCase();
    }

}
