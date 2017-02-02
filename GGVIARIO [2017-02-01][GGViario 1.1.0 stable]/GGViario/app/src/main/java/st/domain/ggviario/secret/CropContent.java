package st.domain.ggviario.secret;

import android.content.res.Configuration;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import st.domain.ggviario.secret.dao.DaoCrop;
import st.domain.ggviario.secret.model.CropSector;
import st.domain.ggviario.secret.adapter.CropSectorAdapter;
import st.domain.ggviario.secret.callbaks.BackHomeUpMenuObserver;
import st.domain.ggviario.secret.callbaks.MenuMapper;

/**
 *
 * Created by xdata on 12/29/16.
 */

public class CropContent extends AppCompatActivity {

    private Toolbar toolbar;
    private MenuMapper menuMapper;
    private RecyclerView rvListCrop;
    private CropSectorAdapter addpter;
    private Date date;
    private List<CropSector> list;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.setContentView(R.layout._crop_datable_date_content);

        this.addpter = new CropSectorAdapter(this);
        Bundle bundle = this.getIntent().getExtras();
        this.date = (Date) bundle.getSerializable("date");
        this.rvListCrop = (RecyclerView) findViewById(R.id.rv_list_crop_sector);
        int columns = (this.getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE)
                ? 3: 2;
        this.addpter.setColumns(columns);

        final StaggeredGridLayoutManager layoutManager = new StaggeredGridLayoutManager(columns, LinearLayoutManager.VERTICAL);
        layoutManager.setGapStrategy(StaggeredGridLayoutManager.GAP_HANDLING_MOVE_ITEMS_BETWEEN_SPANS);

        this.rvListCrop.setHasFixedSize(true);
        layoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        this.rvListCrop.setLayoutManager(layoutManager);

        this.rvListCrop.setLayoutManager(layoutManager);
        this.rvListCrop.setAdapter(this.addpter);


        this.prepareToolbar();

        Thread action = new Thread(new Runnable() {
            @Override
            public void run() {
                populateList();
            }
        });
        this.runOnUiThread(action);
    }



    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_crop, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return this.menuMapper.menuAction(item);
    }


    private void prepareToolbar()
    {
        this.toolbar = (Toolbar) this.findViewById(R.id.toolbar);
        this.menuMapper = new MenuMapper(this);
        DateFormat format = new SimpleDateFormat("dd 'de' MMMM 'de' yyyy");
        String dateTitle = format.format(this.date);
        this.menuMapper.add(new BackHomeUpMenuObserver());
        this.toolbar.setTitle(dateTitle);
        this.toolbar.inflateMenu(R.menu.menucrop_content);

        this.setSupportActionBar(toolbar);
        if(this.getSupportActionBar() != null)
        {
            this.getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            this.getSupportActionBar().setTitle(dateTitle);
            this.toolbar.setTitleTextColor(getResources().getColor(R.color.white));
        }
    }


    private void populateList() {

        this.addpter.clear();
        DaoCrop dao = new DaoCrop(this);
        this.list = dao.loadCropContents(this.date);

        for (CropSector cropSector : this.list){
            this.addpter.add(new CropSectorAdapter.CropSectorDataSet(cropSector, this));
        }
    }


}
