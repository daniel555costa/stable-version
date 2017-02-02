package st.domain.ggviario.secret.adapter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.support.v7.widget.CardView;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;
import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.util.BaseCharacter;

/**
 * Created by xdata on 8/11/16.
 */
public class MainHomeAdapter extends RecyclerViewAdapter {

    public MainHomeAdapter(Context content)
    {
        super(content);
        super.addItemFactory(R.layout._main_home_operation, new ViewHolderFactory() {
            @Override
            public ItemViewHolder factory(View view) {
                return new ItemOperation(view);
            }
        });
    }

//
//    @Override
//    public void onBindViewHolder(BaseRecyclerAdapter.ItemViewHolder viewHolder, BaseRecyclerAdapter.ItemDataSet dataSet, int position, int onRecyclerViewId)
//    {
//        if(viewHolder instanceof ItemOperation)
//        {
//            ItemOperation item = (ItemOperation) viewHolder;
//            DataOperation data = (DataOperation) dataSet;
//            item.setValues(data);
////            if(!data.efeito) support.notifyItemInserted(position);
//        }
//        try {
//            YoYo.with(Techniques.RotateInDownLeft)
//                    .duration(700)
//                    .playOn(viewHolder.itemView)
//            ;
//        }
//        catch (Throwable throwable)
//        {
//            Toast.makeText(this.support.getContext(), "Nao Consegui Pegar a animacao", Toast.LENGTH_SHORT).show();
//        }
//    }
//

//    @Override
//    public View onCreateView(LayoutInflater inflater, final ViewGroup group, final int viewType, int onRecyclerViewId) {
//        final int screenOrientation = this.support.getContext().getResources().getConfiguration().orientation;
//        final int HORIZONTAL_SCREEN = Configuration.ORIENTATION_LANDSCAPE;
//
//        final View itemView = inflater.inflate(R.layout._main_home_operation, group, false);
//
//        itemView.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
//            @Override
//            public boolean onPreDraw() {
//                final int type = viewType;
//                final ViewGroup.LayoutParams layoutParams = itemView.getLayoutParams();
//                if (layoutParams instanceof StaggeredGridLayoutManager.LayoutParams) {
//                    StaggeredGridLayoutManager.LayoutParams staggerLayoutParams = (StaggeredGridLayoutManager.LayoutParams) layoutParams;
//
//                    if (screenOrientation == HORIZONTAL_SCREEN) {
////                        staggerLayoutParams.setFullSpan(false);
////                        staggerLayoutParams.width = itemView.getWidth() - (itemView.getWidth()/2);
//                    }
//                    switch (type) {
//
////                        case 1:
////                            staggerLayoutParams.setFullSpan(true);
////                            break;
////
////                        case 2:
////                            staggerLayoutParams.setFullSpan(false);
////                            staggerLayoutParams.width = itemView.getWidth() + ( itemView.getWidth()/2);
////                            break;
////
////                        case 3:
////                            staggerLayoutParams.setFullSpan(false);
////                            staggerLayoutParams.width = itemView.getWidth() / 2;
////                            staggerLayoutParams.height = itemView.getHeight() / 2;
////                            break;
//                    }
////                    staggerLayoutParams.setFullSpan(false);
////                            staggerLayoutParams.width = itemView.getWidth() / 2;
////                            staggerLayoutParams.height = itemView.getHeight() / 2;
//
//                    itemView.setLayoutParams(staggerLayoutParams);
//                    final StaggeredGridLayoutManager lm = (StaggeredGridLayoutManager) ((RecyclerView) group).getLayoutManager();
//                    lm.invalidateSpanAssignments();
//
//
//                }
//                itemView.getViewTreeObserver().removeOnPreDrawListener(this);
//                return true;
//            }
//        });
//        return itemView;
//    }

    public class ItemOperation extends ItemViewHolder
    {
        private final CardView cardView;
        private final TextView titleOperation;
        private final ImageView imageOperation;
        private DataOperation value;
        private Context context;


        public ItemOperation(View itemView)
        {
            super(itemView);
            this.context = itemView.getContext();
            this.cardView = (CardView) itemView;
            this.imageOperation = (ImageView) this.cardView.findViewById(R.id.img_operation);
            this.titleOperation = (TextView) this.cardView.findViewById(R.id.tv_title_operation);
            this.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    onClink(0);
                }
            });

        }

        @Override
        public void bind(ItemDataSet dataSet) {
            DataOperation values = (DataOperation) dataSet;
            int cardColor =  this.context.getResources().getColor(values.color);
            this.imageOperation.setImageResource(values.image);
            this.titleOperation.setText(values);
            this.cardView.setCardBackgroundColor(cardColor);
            this.value = values;
        }

        public void onClink(int position)
        {
            if(this.value.activity == null) return;
            Intent intent = new Intent(this.context, this.value.activity);
            context.startActivity(intent);
        }
    }

    public static class DataOperation extends BaseCharacter implements ItemDataSet
    {
        private int color;
        private String name;
        private  int image;
        private Class<? extends Activity> activity;
        public boolean efeito;

        public DataOperation color(int color) {
            this.color = color;
            return this;
        }

        public DataOperation name(String operation) {
            this.name = operation;
            return this;
        }

        public DataOperation image(int image) {
            this.image = image;
            return this;
        }

        public DataOperation activity(Class<? extends Activity> activity) {
            this.activity = activity;
            return this;
        }

        public DataOperation efeito(boolean efeito) {
            this.efeito = efeito;
            return this;
        }

        @Override
        public String toString()
        {
            return name.toString();
        }

        public int getLayoutId() {
            return R.layout._main_home_operation;
        }
    }

    public static DataOperation newOperation()
    {
        return new DataOperation();
    }
}
