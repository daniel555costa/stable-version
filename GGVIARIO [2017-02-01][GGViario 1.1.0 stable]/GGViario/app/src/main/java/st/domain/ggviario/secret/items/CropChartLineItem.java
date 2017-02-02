package st.domain.ggviario.secret.items;

import android.content.Context;
import android.content.res.Configuration;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.view.View;
import android.view.ViewGroup;

import com.db.chart.model.LineSet;
import com.db.chart.model.Point;
import com.db.chart.view.LineChartView;

import java.util.Comparator;
import java.util.LinkedList;
import java.util.List;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.adapter.CropChartSectorAdapter;
import st.domain.ggviario.secret.model.Sector;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;
import st.domain.support.android.util.ListOperation;

/**
 *
 * Created by dchost on 28/01/17.
 */

public class CropChartLineItem extends ItemViewHolder {

    private final LineChartView chart;
    private final RecyclerView recyclerView;
    private final RecyclerViewAdapter adapter;
    private ChartDataSet dataSet;

    private Context context;

    public CropChartLineItem(View itemView) {
        super(itemView);
        this.chart = (LineChartView) this.itemView.findViewById(R.id.chart_line_report);
        this.recyclerView = (RecyclerView) this.itemView.findViewById(R.id.rv_chart_sectors);
        this.context = this.itemView.getContext();

        RecyclerView.LayoutManager layoutManager = new StaggeredGridLayoutManager(1, StaggeredGridLayoutManager.VERTICAL);
        this.recyclerView.setLayoutManager(layoutManager);
        this.recyclerView.setAdapter(this.adapter = new CropChartSectorAdapter(this.context));
        this.fullWidth();
    }

    @Override
    public void bind(ItemDataSet dataSet) {
        this.dataSet = (ChartDataSet) dataSet;
        float desity = this.context.getResources().getDisplayMetrics().density;

        for (ChartDataLine dataLine: this.dataSet.datas){
            LineSet line = new LineSet();
            int color = this.context.getResources().getColor(dataLine.colorId);
            line.setColor(color);
            for(Point point: dataLine.points){
                line.addPoint(point);
                line.setSmooth(true); //com curva redonda
            }

            line.setThickness(1*desity);
            try {
                this.chart.addData(line);
            }catch (Exception ex){
                ex.printStackTrace();

            }
        }

        this.adapter.clear();
        List<ItemDataSet> list = this.dataSet.getLegendDescription();

        ListOperation<CropChartSectorItem.CropChartSectorDataSet> listOperation = new ListOperation(list);
        listOperation.sortDesc(new Comparator<CropChartSectorItem.CropChartSectorDataSet>() {
            @Override
            public int compare(CropChartSectorItem.CropChartSectorDataSet o1, CropChartSectorItem.CropChartSectorDataSet o2) {
                int iQuantity = o1.getQuantity();
                int jQunatity = o2.getQuantity();
                int result = (o1.getQuantity() == o2.getQuantity())? 0
                        :(o1.getQuantity()> o2.getQuantity())? 1
                        : -1;

                return result;
            }
        });
        this.adapter.add(list);

//        this.chart.setXLabels(AxisRenderer.LabelPosition.NONE);

        this.chart.setXAxis(false);
        this.chart.setYAxis(false);
        this.chart.notifyDataUpdate();
        this.chart.show();
    }

    private void fullWidth() {
        final int HORIZONTAL_ORIENTATION = Configuration.ORIENTATION_LANDSCAPE;
        final int VERTICAL_ORIENTATION = Configuration.ORIENTATION_PORTRAIT;

        int orientation = this.context.getResources().getConfiguration().orientation;
        final ViewGroup.LayoutParams layoutParams = itemView.getLayoutParams();
        if (layoutParams instanceof StaggeredGridLayoutManager.LayoutParams) {
            final StaggeredGridLayoutManager.LayoutParams staggeredLayoutParmn = (StaggeredGridLayoutManager.LayoutParams) itemView.getLayoutParams();

            if(orientation == VERTICAL_ORIENTATION){

            }
            staggeredLayoutParmn.setFullSpan(true);
        }

    }


    public static class ChartDataSet implements ItemDataSet {

        private List<ChartDataLine> datas;

        public ChartDataSet (){
            this.datas = new LinkedList<>();
        }

        public void addLine(ChartDataLine dataLine) {
            this.datas.add(dataLine);
        }

        public List<ItemDataSet> getLegendDescription(){
            List<ItemDataSet> list = new LinkedList<>();
            for (ChartDataLine line: this.datas) {
                list.add(new CropChartSectorItem.CropChartSectorDataSet(line.colorId, line.sector, line.totalQuantity));
            }
            return list;
        }

        public int getLayoutId() {
            return R.layout._crop_report_chart;
        }

    }

    public static class ChartDataLine {

        private int colorId;
        private List<Point> points;
        private int totalQuantity;
        public Sector sector;

        public ChartDataLine(int colorId, Sector sector, List<Point> points) {
            this.colorId = colorId;
            this.sector = sector;
            this.points = points;
            this.totalQuantity = 0;

            for(Point p : this.points) {
                this.totalQuantity += p.getValue();
            }
        }
    }

    public static RecyclerViewAdapter.ViewHolderFactory factory() {
        return new RecyclerViewAdapter.ViewHolderFactory() {
            @Override
            public ItemViewHolder factory(View view) {
                return new CropChartLineItem(view);
            }
        };
    }
}
