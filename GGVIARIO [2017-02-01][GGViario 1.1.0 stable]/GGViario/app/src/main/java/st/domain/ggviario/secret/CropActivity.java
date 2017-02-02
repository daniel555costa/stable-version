package st.domain.ggviario.secret;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.app.Fragment;
import android.support.v4.view.ViewPager;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;

import st.domain.ggviario.secret.adapter.PagerAdapter;
import st.domain.ggviario.secret.fragments.CropDateFragment;
import st.domain.ggviario.secret.fragments.CropGeralReport;
import st.domain.ggviario.secret.fragments.OnResultActivity;
import st.domain.ggviario.secret.references.RMap;
import st.domain.support.android.view.SlidingTabLayout;

/**
 *
 * Created by dchost on 30/01/17.
 */

public class CropActivity extends AppCompatActivity {

    private ViewPager viewPager;
    private SlidingTabLayout slidingTabLayout;
    private FloatingActionButton floatingActionButton;
    private Toolbar toolbar;
    private PagerAdapter pagerAdapter;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        Log.i("APP.GGVIARIO", "CropActivity.onCreate");

        super.onCreate(savedInstanceState);
        this.setContentView(R.layout._crop);


        //ToolBar
        this.toolbar = (Toolbar) this.findViewById(R.id.toolbar);
        this.toolbar.setTitleTextColor(getResources().getColor(R.color.white));
        this.toolbar.setTitle(R.string.crop);

        this.setSupportActionBar(this.toolbar);
        ActionBar actionBar = this.getSupportActionBar();


        // View Pager
        this.viewPager = (ViewPager) this.findViewById(R.id.view_pager);
        this.pagerAdapter = new PagerAdapter(this.getSupportFragmentManager(), this);

        this.slidingTabLayout = (SlidingTabLayout) this.findViewById(R.id.view_pager_tabs);
        this.slidingTabLayout.setCustomTabView(R.layout.aba, R.id.aba_title);
        this.slidingTabLayout.setBackgroundColor(getResources().getColor(R.color.colorPrimary));
        this.slidingTabLayout.setSelectedIndicatorColors(this.getResources().getColor(R.color.white));


        CropGeralReport geralReport = new CropGeralReport();
        pagerAdapter.addFragment("Report", geralReport);

        CropDateFragment dayFragment = new CropDateFragment();
        pagerAdapter.addFragment("Diario", dayFragment);

        this.viewPager.setAdapter(pagerAdapter);
        this.slidingTabLayout.setViewPager(this.viewPager);




        // FloatingActionButton
        this.floatingActionButton = (FloatingActionButton) this.findViewById(R.id.fab_new_crop);
        this.floatingActionButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                newCrop();
            }
        });


        CropGeralReport cropReport = new CropGeralReport();
        Bundle bundle = new Bundle();
        cropReport.setArguments(bundle);
        // this.adapterPager.addFragment("Visão", cropReport);


        bundle = new Bundle();
        dayFragment.setArguments(bundle);
        //this.adapterPager.addFragment("Diario", dayFragment);
    }

    private void newCrop() {
        Log.i("APP.GGVIARIO", "-> CropActivity.newCrop");

        Intent intent = new Intent(this, CropNewActivity.class);
        this.startActivityForResult(intent, RMap.REQUEST_NEW_CROP);
    }

    @Override
    protected void onStart() {
        Log.i("APP.GGVIARIO", "-> CropActivity.onStart");
        super.onStart();
    }

    @Override
    protected void onResume() {
        Log.i("APP.GGVIARIO", "-> CropActivity.onResume");
        super.onResume();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i("APP.GGVIARIO", "-> CropActivity.onActivityResult");

        onResult(requestCode, resultCode, data);
    }

    private void onResult(int requestCode, int resultCode, Intent data) {
        Log.i("APP.GGVIARIO", "-> CropActivity.onResult");
        for(Fragment fragment: this.getSupportFragmentManager().getFragments()) {
            if((fragment instanceof OnResultActivity)) {
                    if(((OnResultActivity) fragment).onResultActivity(requestCode, resultCode, data, this))
                        break;
            }
        }
    }
}
