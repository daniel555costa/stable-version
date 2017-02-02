package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.model.CropSector;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;

/**
 *
 * Created by xdata on 12/29/16.
 */
public class CropSectorAdapter extends RecyclerViewAdapter {

    private int columns;

    public CropSectorAdapter(Context context) {
        super(context);

        super.addItemFactory(R.layout._crop_datable_date_content_sector,
                new ViewHolderFactory() {
                    @Override
                    public ItemViewHolder factory(View view) {
                        return new CropSectorViewHolder(view);
                    }
                });
    }

    public void setColumns(int columns) {
        this.columns = columns;
    }


    private class CropSectorViewHolder extends ItemViewHolder
    {
        private TextView tvQuantity;
        private TextView tvSector;
        private TextView tvPercas;
        private CropSectorDataSet dataSet;

        CropSectorViewHolder(View view) {
            super(view);
            this.tvQuantity = (TextView) this.itemView.findViewById(R.id.tv_crop_content_qunatity);
            this.tvSector = (TextView) this.itemView.findViewById(R.id.tv_crop_content_sector);
            this.tvPercas = (TextView) this.itemView.findViewById(R.id.tv_crop_content_percas);



        }

        @Override
        public void bind(ItemDataSet dataSet) {
            if(dataSet instanceof CropSectorDataSet) {
                this.dataSet = (CropSectorDataSet) dataSet;
                this.prepare();
            }
        }

        private void prepare() {

            this.tvQuantity.setText(this.dataSet.quantity());
            this.tvSector.setText(this.dataSet.cropSector.getSector().getName());
            String percas = this.dataSet.quantityPercas()
                    + this.dataSet.quantityPercasGalinhas();
            this.tvPercas.setText(percas);

            updateMargin();
        }

        private void updateMargin() {
            ViewGroup.LayoutParams layoutParm = this.itemView.getLayoutParams();
            if(layoutParm != null && layoutParm instanceof StaggeredGridLayoutManager.LayoutParams ){

                int pos = getAdapterPosition();
                int length = getItemCount();
                int itemPerRown = columns -1;

                int left = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).leftMargin;
                int top = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).topMargin;
                int right = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).rightMargin;
                int bottom = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).bottomMargin;
                float dimension = context.getResources().getDisplayMetrics().density;

                if(pos <= itemPerRown){
                    top = (int) (dimension * 8);
                }else if( pos > (length - itemPerRown)){
                    bottom = (int) (dimension * 8);
                }

                ((StaggeredGridLayoutManager.LayoutParams) layoutParm)
                        .setMargins(left, top, right, bottom);
            }
        }
    }



    public static class CropSectorDataSet extends CropAdapter.CropDataSet{

        private CropSector cropSector;

        public CropSectorDataSet(CropSector cropSector, Context context) {
            super(cropSector, context);
            this.cropSector = cropSector;
        }

        @Override
        public int getLayoutId() {
            return R.layout._crop_datable_date_content_sector;
        }

        public CropSector getCropSector() {
            return cropSector;
        }

        @Override
        String quantityPercas() {
            return (this.cropSector.getQuantityPerca()>0)?
                    String.valueOf(cropSector.getQuantityPerca())+context.getString(R.string.quebrados):
                    "";
        }

        @Override
        String quantityPercasGalinhas() {
            return (this.cropSector.getQuantityPercaGalinha()>0)?
                    String.valueOf(cropSector.getQuantityPercaGalinha())+context.getString(R.string.kill):
                    "";
        }


    }
}
