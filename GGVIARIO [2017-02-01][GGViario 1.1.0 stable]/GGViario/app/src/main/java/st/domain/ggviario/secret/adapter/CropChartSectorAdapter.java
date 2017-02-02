package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.view.View;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.items.CropChartSectorItem;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;

/**
 *
 * Created by dchost on 29/01/17.
 */

public class CropChartSectorAdapter extends RecyclerViewAdapter {

    public CropChartSectorAdapter(Context context) {
        super(context);
        this.addItemFactory(R.layout._crop_report_chart_sector,
                new ViewHolderFactory() {
                    @Override
                    public ItemViewHolder factory(View view) {
                        return new CropChartSectorItem(view);
                    }
                });
    }
}
