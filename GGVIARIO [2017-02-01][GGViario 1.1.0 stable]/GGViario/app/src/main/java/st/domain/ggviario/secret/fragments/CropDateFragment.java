package st.domain.ggviario.secret.fragments;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;

import st.domain.ggviario.secret.CropContent;
import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.adapter.CropAdapter;
import st.domain.ggviario.secret.dao.DaoCrop;
import st.domain.ggviario.secret.items.TextSeparatorItem;
import st.domain.ggviario.secret.model.Crop;
import st.domain.ggviario.secret.references.RMap;

/**
 *
 * Created by dchost on 30/01/17.
 */

public class CropDateFragment extends LogFragment implements CropAdapter.OpenCrop, OnResultActivity {

    private View rootView;
    private RecyclerView recyclerView;
    private CropAdapter adapter;
    private List<Crop> list;
    private Context context;

    @Override
    public void onAttach(Context context) {
        Log.i("APP.GGVIARIO", "-> CropDateFragment.onAttach");

        super.onAttach(context);
        this.context = context;
    }


    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        Log.i("APP.GGVIARIO", "-> CropDateFragment.onCreateView");

        this.rootView = inflater.inflate(R.layout._crop_datable, container, false);
        this.recyclerView = (RecyclerView) rootView.findViewById(R.id.rv_crop_datable);
        this.adapter = new CropAdapter(this.context);

        this.recyclerView.setLayoutManager(new StaggeredGridLayoutManager(1, StaggeredGridLayoutManager.VERTICAL));
        this.recyclerView.setAdapter(this.adapter);

        ((Activity) this.context).runOnUiThread(
                new Runnable() {
                    @Override
                    public void run() {
                        populateList();
                    }
                }
        );
        return this.rootView;
    }


    private void populateList() {
        Log.i("APP.GGVIARIO", "-> CropDateFragment.populateList");

        DaoCrop daoCrop = new DaoCrop(this.context);
        this.list = daoCrop.loadCropData();
        this.adapter.setOpenCrop(this);

        Calendar lastDate = null;
        Calendar auxDate;
        Calendar mesPast = Calendar.getInstance();
        mesPast.add(Calendar.MONTH, -1);


        DateFormat monthFormatter = new SimpleDateFormat(this.context.getString(R.string.month_of));
        DateFormat yearFormatter = new SimpleDateFormat(this.context.getString(R.string.year_of_month_of));
        int iCountMesPast = 0;
        for(st.domain.ggviario.secret.model.Crop crop: list) {
            auxDate = Calendar.getInstance();
            auxDate.setTime(crop.getDate());

            if(lastDate == null)
                lastDate = auxDate;

            if(Calendar.getInstance().get(Calendar.YEAR) == auxDate.get(Calendar.YEAR)
                    && Calendar.getInstance().get(Calendar.MONTH) == auxDate.get(Calendar.MONTH)
                    && this.adapter.getItemCount() == 0 ) {
                adapter.add(new TextSeparatorItem.TextSeparatorDataSet(R.string.this_month));
            }
            else if (mesPast.get(Calendar.YEAR) == auxDate.get(Calendar.YEAR)
                    && mesPast.get(Calendar.MONTH) ==  auxDate.get(Calendar.MONTH)
                    && iCountMesPast == 0){

                iCountMesPast ++;
                adapter.add(new TextSeparatorItem.TextSeparatorDataSet(R.string.past_month));
            }
            else if(lastDate.get(Calendar.YEAR) == auxDate.get(Calendar.YEAR)
                    && lastDate.get(Calendar.MONTH) != auxDate.get(Calendar.MONTH)) {
                String text = monthFormatter.format(auxDate.getTime());
                adapter.add(new TextSeparatorItem.TextSeparatorDataSet(text));
            }
            else if(lastDate.get(Calendar.YEAR) != auxDate.get(Calendar.YEAR)) {
                String text = yearFormatter.format(auxDate.getTime());
                adapter.add(new TextSeparatorItem.TextSeparatorDataSet(text));
            }

            adapter.add(new CropAdapter.CropDataSet(crop, this.context));
            lastDate = auxDate;
        }
        //daoCrop.close();
    }

    @Override
    public void openCrop(st.domain.ggviario.secret.model.Crop dataSet) {
        Log.i("APP.GGVIARIO", "-> CropDateFragment.openCrop");

        Intent intent = new Intent(this.getContext(), CropContent.class);
        Bundle b = new Bundle();
        b.putSerializable("date", dataSet.getDate());
        intent.putExtras(b);
        startActivity(intent);

    }

    @Override
    public boolean onResultActivity(int requestCode, int resultCode, Intent data, Context context) {
        Log.i("APP.GGVIARIO", "-> CropDateFragment.onResultActivity");

        if(this.context == null && context != null)  {
            Log.i("APP.GGVIARIO", "The current context is null");
            this.context = context;
        }

        switch (requestCode) {
            case RMap.REQUEST_NEW_CROP:
                this.adapter.clear();
                this.populateList();
                break;
        }

        return false;
    }
}
