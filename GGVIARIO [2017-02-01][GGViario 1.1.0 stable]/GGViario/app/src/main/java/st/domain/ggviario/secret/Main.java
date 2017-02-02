package st.domain.ggviario.secret;

import android.os.Bundle;
import android.support.v4.view.ViewPager;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;

import st.domain.ggviario.secret.adapter.PagerAdapter;
import st.domain.ggviario.secret.dao.Dao;
import st.domain.ggviario.secret.fragments.MainHome;
import st.domain.support.android.view.SlidingTabLayout;

public class Main extends AppCompatActivity {

    private ViewPager pager;
    private SlidingTabLayout slidingTabLayout;
    private Toolbar toolbar;

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        // INIT
        super.onCreate(savedInstanceState);
        setContentView(R.layout._main);
        Dao.inti(this);



        // TollBar
        this.toolbar = (Toolbar) this.findViewById(R.id.toolbar);
        this.toolbar.setTitle(R.string.app_name);
        this.toolbar.setTitleTextColor(getResources().getColor(R.color.white));

//        this.toolbar.setLogo();
//        this.toolbar.setSubtitle();
        this.setSupportActionBar(this.toolbar);



        //View Pager
        this.pager = (ViewPager) this.findViewById(R.id.view_pager);
        this.slidingTabLayout = (SlidingTabLayout) this.findViewById(R.id.view_pager_tabs);
        this.slidingTabLayout.setBackgroundColor(getResources().getColor(R.color.colorPrimary));
        this.slidingTabLayout.setSelectedIndicatorColors(getResources().getColor(R.color.white));

        MainHome home = new MainHome();
        PagerAdapter viewPagerAdapter = new PagerAdapter(this.getSupportFragmentManager(), this);
        viewPagerAdapter.addFragment("MAIN", home);

        this.pager.setAdapter(viewPagerAdapter);
        this.slidingTabLayout.setCustomTabView(R.layout.aba, R.id.aba_title);
        this.slidingTabLayout.setViewPager( this.pager );
    }

    @Override
    protected void onDestroy() {

        super.onDestroy();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu)
    {
        getMenuInflater().inflate(R.menu.menu_toolbar_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return super.onOptionsItemSelected(item);
    }
}
