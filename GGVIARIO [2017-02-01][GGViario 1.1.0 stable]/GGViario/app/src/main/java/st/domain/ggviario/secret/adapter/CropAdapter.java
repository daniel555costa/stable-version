package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import java.text.SimpleDateFormat;
import java.util.Calendar;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.model.Crop;
import st.domain.ggviario.secret.items.TextSeparatorItem;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;

/**
 *
 * Created by xdata on 12/24/16.
 */

public class CropAdapter extends RecyclerViewAdapter {

    private OpenCrop openCrop;

    public CropAdapter (Context context) {
        super(context);

        this.addItemFactory(R.layout._crop_datable_date,
                new ViewHolderFactory() {
                    @Override
                    public ItemViewHolder factory(View view) {
                        return new CropViewHolder(view);
                    }
                });

        this.addItemFactory(R.layout.item_textseparator, TextSeparatorItem.factoryInstance());
    }

    public void setOpenCrop(OpenCrop openCrop){
        this.openCrop = openCrop;
    }

    private void openCrop(CropDataSet dataSet){
        if(this.openCrop != null)
            this.openCrop.openCrop(dataSet.crop);
    }

    private class CropViewHolder extends ItemViewHolder {

        private CropDataSet dataSet;
        private TextView tvDate;
        private TextView tvQuantity;
        private TextView tvQuantityPerca;
        private TextView tvQuantityPercaGalinha;


        public CropViewHolder(View itemView) {

            super(itemView);

            this.tvDate = (TextView) this.itemView.findViewById(R.id.tv_crop_date);
            this.tvQuantity = (TextView) this.itemView.findViewById(R.id.tv_crop_quantity);
            this.tvQuantityPerca = (TextView) this.itemView.findViewById(R.id.tv_crop_quantity_percas);
            this.tvQuantityPercaGalinha = (TextView) this.itemView.findViewById(R.id.tv_qunatity_perca_gaclinha);
            this.itemView.setOnClickListener(
                    new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            openCrop(dataSet);
                        }
                    }
            );

        }


        /**
         *
         * @param dataSet
         */
        @Override
        public void bind(ItemDataSet dataSet) {

            this.dataSet = (CropDataSet) dataSet;
            this.tvDate.setText(this.dataSet.date());
            this.tvQuantity.setText(this.dataSet.quantity());

            this.tvQuantityPerca.setText(this.dataSet.quantityPercas());
            this.tvQuantityPercaGalinha.setText(this.dataSet.quantityPercasGalinhas());

            if (!this.dataSet.crop.hasPerca()) this.tvQuantityPerca.setVisibility(View.GONE);
            else this.tvQuantityPerca.setVisibility(View.VISIBLE);
            if (!this.dataSet.crop.hasPercaGalinhas()) this.tvQuantityPercaGalinha.setVisibility(View.GONE);
            else this.tvQuantityPercaGalinha.setVisibility(View.VISIBLE);

            updateMargin();

        }

        private void updateMargin() {
            ViewGroup.LayoutParams layoutParm = this.itemView.getLayoutParams();
            if(layoutParm instanceof StaggeredGridLayoutManager.LayoutParams){

                int index = getAdapterPosition();
                int length = getItemCount();
                int itemPerRown = 1;

                int left = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).leftMargin;
                int right = ((StaggeredGridLayoutManager.LayoutParams) layoutParm).rightMargin;

                float dimension = context.getResources().getDisplayMetrics().density;


                int bottom = (int) (dimension * 0);
                int top = (int) (dimension * 0);

                if( index + 1 == length){
                    bottom = (int) (dimension * 16);
                }

                ((StaggeredGridLayoutManager.LayoutParams) layoutParm)
                        .setMargins(left, top, right, bottom);
            }
        }
    }

    public static class CropDataSet implements ItemDataSet {

        private final Crop crop;
        private int type;
         Context context;

        public  CropDataSet(Crop crop, Context context)
        {
            this.crop = crop;
            this.context = context;
        }

        public int getLayoutId() {
            return R.layout._crop_datable_date;
        }


        String quantity () {
            return String.valueOf(this.crop.getQuantity());
        }

        String quantityPercas(){
            return "Quebrados: "+String.valueOf(this.crop.getQuantityPerca());
        }

        String quantityPercasGalinhas() {
            return "Mortes: "+String.valueOf(this.crop.getQuantityPercaGalinha());
        }

        String date() {
            Calendar instance = Calendar.getInstance();

            Calendar date = Calendar.getInstance();
            date.setTime(this.crop.getDate());

            SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
            String sDate = format.format(date.getTime());

            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.today);

            instance.add(Calendar.DAY_OF_MONTH, -1);
            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.ontem);

            instance.add(Calendar.DAY_OF_MONTH, -1);
            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.dois_dias_atraz);

            instance.add(Calendar.DAY_OF_MONTH, -1);
            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.trez_dias_atras);

            instance.add(Calendar.DAY_OF_MONTH, -1);
            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.quatro_dias_atraz);

            instance.add(Calendar.DAY_OF_MONTH, -1);
            if(sDate.equals(format.format(instance.getTime())))
                return context.getString(R.string.cinco_dias_atraz);

            instance = Calendar.getInstance();

            if(instance.get(Calendar.YEAR) == date.get(Calendar.YEAR)
                    && instance.get(Calendar.MONTH) == date.get(Calendar.MONTH))
            {
                format = new SimpleDateFormat("dd");
                return "Dia "+format.format(date.getTime());
            }

            format = new SimpleDateFormat("dd 'de' MMMM");
            return format.format(date.getTime());
        }

        public int getType() {
            return type;
        }
    }

    public interface OpenCrop{
        void openCrop(Crop dataSet);
    }
}
