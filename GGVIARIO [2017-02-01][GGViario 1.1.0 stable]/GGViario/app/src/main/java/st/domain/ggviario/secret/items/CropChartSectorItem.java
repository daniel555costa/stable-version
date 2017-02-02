package st.domain.ggviario.secret.items;

import android.content.Context;
import android.view.View;
import android.widget.TextView;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.model.Sector;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.util.ShapDrawableBuilder;

/**
 *
 * Created by dchost on 29/01/17.
 */

public class CropChartSectorItem extends ItemViewHolder {

    private final TextView tvQuantity;
    private final TextView tvSectorNAme;
    private final View viewColor;
    private final Context context;
    private CropChartSectorDataSet dataSet;

    public CropChartSectorItem(View itemView) {
        super(itemView);
        this.viewColor = this.itemView.findViewById(R.id.tv_crop_color);
        this.tvSectorNAme = (TextView) this.itemView.findViewById(R.id.tv_crop_sector);
        this.tvQuantity = (TextView) this.itemView.findViewById(R.id.tv_crop_quantity);
        this.context = this.itemView.getContext();
    }

    @Override
    public void bind(ItemDataSet dataSet) {

        this.dataSet = (CropChartSectorDataSet) dataSet;
        ShapDrawableBuilder drawableBuilder = new ShapDrawableBuilder(this.context);
        drawableBuilder.shap(ShapDrawableBuilder.Shap.OVAL)
                .solidColor(this.dataSet.colorId);
        this.tvQuantity.setText(String.valueOf(this.dataSet.totalQuantity));
        this.viewColor.setBackground(drawableBuilder.build());
        this.tvSectorNAme.setText(this.dataSet.sector.getName());

    }

    public static class CropChartSectorDataSet implements ItemDataSet{
        private int colorId;
        private Sector sector;
        private int totalQuantity;

        public CropChartSectorDataSet(int colorId, Sector sector, int totalQuantity) {
            this.colorId = colorId;
            this.sector = sector;
            this.totalQuantity = totalQuantity;
        }

        public int getLayoutId() {
            return R.layout._crop_report_chart_sector;
        }

        public int getQuantity() {
            return totalQuantity;
        }
    }
}
