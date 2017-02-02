package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v7.widget.AppCompatAutoCompleteTextView;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;

import java.util.LinkedList;
import java.util.List;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.callbaks.DespesaDelectAction;

/**
 * Created by xdata on 12/21/16.
 */

public class FaturaAdapter extends RecyclerView.Adapter implements DespesaDelectAction {

    private final LayoutInflater inflate;
    private final List<FaturaDataSet> listFatura;
    private Context context;

    public FaturaAdapter(Context context)
    {

        this.context =  context;
        this.inflate = LayoutInflater.from(this.context);
        this.listFatura = new LinkedList<>();

    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        View view = inflate.inflate(R.layout._despesa_fornecedor, parent, false);
        FaturaViewHolder faturaViewHolder = new FaturaViewHolder(view, this);
        return faturaViewHolder;
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int index) {

        assert holder instanceof FaturaViewHolder;
        FaturaDataSet dataSet = this.listFatura.get(index);
        ((FaturaViewHolder) holder).bind(dataSet);
    }

    public void add ()
    {
        this.listFatura.add(new FaturaDataSet());
        this.notifyItemInserted(this.listFatura.size()-1);
    }

    @Override
    public int getItemCount() {
        return this.listFatura.size();
    }

    @Override
    public void accept(FaturaDataSet dataSet) {

        int index = this.listFatura.indexOf(dataSet);
        this.notifyItemRemoved(index);
        this.listFatura.remove(index);

    }


    public class FaturaViewHolder extends RecyclerView.ViewHolder implements FaturaItemAdapter.FaturaItemAction {

        private final FaturaItemAdapter adapter;
        private final DespesaDelectAction delectAction;
        private AppCompatAutoCompleteTextView fornecedorName;
        private RecyclerView listItem;
        private ImageButton btAddNew;
        private ImageButton btClearAll;
        private ImageButton btRemoveDespesa;
        private FaturaDataSet dataSet;

        public FaturaViewHolder(View itemView, final DespesaDelectAction delectAction) {

            super(itemView);
            this.delectAction = delectAction;

            this.fornecedorName = (AppCompatAutoCompleteTextView) itemView.findViewById(R.id.ac_fornecedor_name);
            fornecedorName.setOnKeyListener(new View.OnKeyListener() {
                @Override
                public boolean onKey(View v, int keyCode, KeyEvent event) {
                    dataSet.nameFornecedor = fornecedorName.getText().toString();
                    return true;
                }
            });

            this.btAddNew = (ImageButton) itemView.findViewById(R.id.bt_fatura_add_item);
            btAddNew.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    adapter.addItem();
                }
            });

            this.btClearAll = (ImageButton) itemView.findViewById(R.id.bt_fatura_clear_all);
            this.btClearAll.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    adapter.clear();
                }
            });

            this.btRemoveDespesa = (ImageButton) itemView.findViewById(R.id.bt_despesa_delete);
            this.btRemoveDespesa.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    delectAction.accept(dataSet);
                }
            });

            this.listItem = (RecyclerView) itemView.findViewById(R.id.rv_fornecedor_items);
            this.adapter = new FaturaItemAdapter(itemView.getContext(), this);
            this.prepareList();
            adapter.addItem();

        }

        private void prepareList() {

            RecyclerView.LayoutManager llm = new LinearLayoutManager(itemView.getContext(), LinearLayoutManager.VERTICAL, false);
            listItem.setLayoutManager(llm);
            listItem.setAdapter(this.adapter);

        }

        public void bind( FaturaDataSet dataSet )
        {
            this.dataSet = dataSet;
            this.fornecedorName.setText(dataSet.nameFornecedor);
        }

        @Override
        public void removede() {

        }
    }


    public class FaturaDataSet {

        String nameFornecedor;
    }

}
