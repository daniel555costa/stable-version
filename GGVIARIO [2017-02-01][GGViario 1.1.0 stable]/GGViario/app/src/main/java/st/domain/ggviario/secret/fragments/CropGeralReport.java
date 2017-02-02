package st.domain.ggviario.secret.fragments;

import android.app.Activity;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.db.chart.model.Point;

import java.util.List;

import st.domain.ggviario.secret.items.CropChartLineItem;
import st.domain.ggviario.secret.adapter.MainReportAdapter;
import st.domain.ggviario.secret.dao.DaoCrop;
import st.domain.ggviario.secret.dao.DaoSector;
import st.domain.ggviario.secret.model.Sector;
import st.domain.ggviario.secret.references.RColors;
import st.domain.support.android.adapter.RecyclerViewAdapter;
import st.domain.ggviario.secret.R;

/**
 *
 * Created by xdata on 8/11/16.
 */
public class CropGeralReport extends Fragment
{
    private  String title;
    private View rootview;
    private RecyclerView reportsRecyclerView;
    private RecyclerViewAdapter adapter;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        this.rootview = inflater.inflate(R.layout._crop_report, container, false);
        this.reportsRecyclerView = (RecyclerView) this.rootview;

        RecyclerView.LayoutManager llm = new StaggeredGridLayoutManager(2, StaggeredGridLayoutManager.VERTICAL);
        this.adapter = new MainReportAdapter(this.getContext());
        this.reportsRecyclerView.setLayoutManager(llm);
        this.reportsRecyclerView.setAdapter(this.adapter);

        Activity c = (Activity) this.getContext();
        c.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                populate();
            }
        });

        return  rootview;
    }

    private void populate() {
        CropChartLineItem.ChartDataSet chartDatSet;
        this.adapter.add(chartDatSet = new CropChartLineItem.ChartDataSet());

        DaoSector daoSector = new DaoSector(this.getContext());
        DaoCrop daoCrop = new DaoCrop(this.getContext());

        List<Point> list = daoCrop.reportCropSector(null, DaoCrop.ReportType.MONTH);
        chartDatSet.addLine(new CropChartLineItem.ChartDataLine(R.color.colorAccent, new Sector(null, "Total"), list));

        for(Sector sector: daoSector.loadSector()){
            list = daoCrop.reportCropSector(sector.getId(), DaoCrop.ReportType.MONTH);
            int color = RColors.switchColor(RColors.SECTOR_COLORS, sector.getId());
            chartDatSet.addLine(new CropChartLineItem.ChartDataLine(color, sector, list));
        }

        //daoCrop.close();
        //daoSector.close();
    }

    public void setTitle(String title) {
        this.title = title;
    }

}
