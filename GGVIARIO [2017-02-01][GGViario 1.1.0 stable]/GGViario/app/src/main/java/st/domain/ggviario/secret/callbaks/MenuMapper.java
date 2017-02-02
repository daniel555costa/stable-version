package st.domain.ggviario.secret.callbaks;

import android.app.Activity;
import android.view.MenuItem;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by Daniel Costa at 9/3/16.
 * Using user computer xdata
 */
public class MenuMapper {

    private final Activity activity;
    private Map<Integer, MenuObserver> map;

    public MenuMapper(Activity activity) {
        this.map  = new HashMap<>();
        this.activity = activity;
    }

    public void add(MenuObserver menuObserver) {
        map.put(menuObserver.getKey(), menuObserver);
    }

    public boolean menuAction(MenuItem menuItem) {
        MenuObserver observer = map.get(menuItem.getItemId());
        if(observer != null)
            return observer.accept(menuItem, this.activity);
        return false;
    }
 }
