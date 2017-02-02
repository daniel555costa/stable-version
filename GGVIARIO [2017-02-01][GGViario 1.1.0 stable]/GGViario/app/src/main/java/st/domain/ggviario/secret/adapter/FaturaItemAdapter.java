package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageButton;

import java.util.LinkedList;
import java.util.List;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.callbaks.FaturaItemRemoveAction;

/**
 * Created by xdata on 12/21/16.
 */

public class FaturaItemAdapter extends RecyclerView.Adapter implements FaturaItemRemoveAction {

    private final Context context;
    private List<ItemDataSet> listItem;
    private LayoutInflater inflater;
    private FaturaItemAction action;

    public FaturaItemAdapter(Context context, FaturaItemAction action)
    {
        this.context = context;
        this.inflater = LayoutInflater.from(this.context);
        this.action = action;
        this.listItem = new LinkedList<>();
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        View view = this.inflater.inflate(R.layout._despesa_fornecedor_item, parent, false);
        FaturaItemViewHolder item = new FaturaItemViewHolder(view, this);
        return item;

    }



    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        assert holder instanceof FaturaItemViewHolder;
        ItemDataSet dataSet = this.listItem.get(position);
        ((FaturaItemViewHolder) holder).bind(dataSet);
    }

    @Override
    public int getItemCount() {
        return listItem.size();
    }

    @Override
    public void accept(ItemDataSet dataSet) {

        int indexItem = this.listItem.indexOf(dataSet);
        listItem.remove(indexItem);
        notifyItemRemoved(indexItem);
        if(action != null)
            action.removede();

    }

    void addItem()
    {
        Log.i("GGVIARIO@LOG", "addItem");
        listItem.add(new ItemDataSet());
        notifyItemInserted(listItem.size()-1);
    }

    void clear() {

        this.notifyItemRangeRemoved(0, listItem.size());
        this.listItem.clear();

    }

    class FaturaItemViewHolder extends RecyclerView.ViewHolder {

        private final FaturaItemRemoveAction removeAction;
        private EditText edName;
        private EditText edPrice;
        private EditText edQuantity;
        private ImageButton btRemoveItem;
        private int index;
        private ItemDataSet dataSet;

        FaturaItemViewHolder(View itemView, final FaturaItemRemoveAction removeAction) {

            super(itemView);
            this.removeAction = removeAction;

            this.edName = (EditText) itemView.findViewById(R.id.ed_fatura_item_name);
            this.edPrice = (EditText) itemView.findViewById(R.id.ed_fatura_item_price);
            this.edQuantity = (EditText) itemView.findViewById(R.id.ed_fatura_item_quantity);
            this.btRemoveItem = (ImageButton) itemView.findViewById(R.id.bt_fatura_item_delete);

            this.btRemoveItem.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    removeAction.accept(dataSet);
                }
            });
        }

        void bind(ItemDataSet dataSet){

            this.dataSet = dataSet;

            this.edName.setText(this.dataSet.name);
            this.edQuantity.setText(String.valueOf(this.dataSet.quantity));
            this.edPrice.setText(String.valueOf(this.dataSet.price));

        }

    }

    public class ItemDataSet {

        private String name = "";
        private String quantity = "1";
        private String price = "";

    }

    public interface FaturaItemAction {

        void removede();

    }
}
