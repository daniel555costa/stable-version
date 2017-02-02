package st.domain.ggviario.secret;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.AppCompatSpinner;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.EditText;
import android.widget.Toast;

import st.domain.ggviario.secret.dao.DaoCrop;
import st.domain.ggviario.secret.model.Sector;
import st.domain.ggviario.secret.adapter.SectorAdapter;
import st.domain.ggviario.secret.callbaks.BackHomeUpMenuObserver;
import st.domain.ggviario.secret.callbaks.MenuMapper;
import st.domain.ggviario.secret.callbaks.MenuObserver;
import st.domain.ggviario.secret.references.RMap;


/**
 *
 * Created by xdata on 8/12/16.
 */

// TextStepper, ProgressStepper, DotStepper, TabStepper
public class CropNewActivity extends AppCompatActivity
{
    Toolbar toolbar;
    AppCompatSpinner spinner;
    private MenuMapper menuMapper;
    private EditText edQuantity;
    private EditText edQuantityPercas;
    private EditText edQuantityPercasGalinha;
    private SectorAdapter sectorAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        super.setContentView(R.layout._crop_new);


        this.spinner = (AppCompatSpinner) this.findViewById(R.id.sector_spnner);
        this.edQuantity = (EditText) this.findViewById(R.id.ed_crop_quantity);
        this.edQuantityPercas = (EditText) this.findViewById(R.id.ed_crop_quantity_perca);
        this.edQuantityPercasGalinha = (EditText) this.findViewById(R.id.ed_crop_quantity_percas_galinha);

        this.prepareToolbar();

        this.spinner.setAdapter(this.sectorAdapter = new SectorAdapter(this));


    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_crop_new, menu);
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

        this.menuMapper.add(new MenuObserver() {
            @Override
            public boolean accept(MenuItem menuItem, Activity activity) {
                setResult(10, new Intent());
                finish();
                return true;
            }

            @Override
            public int getKey() {
                return android.R.id.home;
            }
        });

        this.menuMapper.add(new MenuObserver() {
            @Override
            public boolean accept(MenuItem menuItem, Activity activity) {
                return concluir();
            }

            @Override
            public int getKey() {
                return R.id.opt_done;
            }
        });


        this.toolbar.setTitle(R.string.new_crop);
        this.toolbar.inflateMenu(R.menu.menu_crop_new);

        this.setSupportActionBar(toolbar);
        if(this.getSupportActionBar() != null) {
            this.getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            this.getSupportActionBar().setTitle(R.string.new_crop);
            this.toolbar.setTitleTextColor(getResources().getColor(R.color.white));
        }
    }


    private boolean concluir() {

        String tQuantity = this.edQuantity.getText().toString();
        String tQuantityPercas = this.edQuantityPercas.getText().toString();
        String tQuantityPercasGalinha = this.edQuantityPercasGalinha.getText().toString();
        int index = this.spinner.getSelectedItemPosition();

        if(tQuantity.isEmpty()) tQuantity = "0";
        if(tQuantityPercas.isEmpty()) tQuantityPercas = "0";
        if(tQuantityPercasGalinha.isEmpty()) tQuantityPercasGalinha = "0";

        if(index == 0) {
            Toast.makeText(this, R.string.select_sector, Toast.LENGTH_LONG).show();
            return false;
        }


        int quantity = Integer.parseInt(tQuantity);
        int quantityPercas = Integer.parseInt(tQuantityPercas);
        int quantityPercasGalinha = Integer.parseInt(tQuantityPercasGalinha);

        if(quantity == 0
                && quantityPercas == 0
                && quantityPercasGalinha == 0){
            Toast.makeText(this, R.string.comple_the_camp, Toast.LENGTH_LONG).show();
            return false;
        }

        Sector sector = this.sectorAdapter.getItem(index);

        DaoCrop  daoCrop = new DaoCrop(this.getApplicationContext());
        daoCrop.register(quantity, sector, quantityPercas, quantityPercasGalinha);
        //daoCrop.close();

        Intent intent = new Intent();
        intent.putExtra("quantity", quantity);
        intent.putExtra("quantityPerca", quantityPercas);
        intent.putExtra("quantityPercasGalinha", quantityPercasGalinha);
        intent.putExtra("sector", sector.getId());

        this.setResult(RMap.REQUEST_NEW_CROP, intent);
        this.finish();
        return true;
    }

    @Override
    public void onBackPressed() {

        this.finish();
    }

}
