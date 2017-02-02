package st.domain.ggviario.secret.adapter;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import java.util.LinkedList;
import java.util.List;

import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.dao.Dao;
import st.domain.ggviario.secret.dao.DaoSector;
import st.domain.ggviario.secret.model.Sector;


/**
 *
 * Created by xdata on 12/21/16.
 */

public class SectorAdapter extends BaseAdapter {


    private List<Sector> list;
    private  Context context;

    public SectorAdapter(Context context)
    {
        this.list = new LinkedList();
        this.context = context;

        DaoSector daoSector = new DaoSector(context);

        list.add(new Sector(-1, "Selecione sector"));
        list.addAll(daoSector.loadSector());
    }


    @Override
    public int getCount() {
        return this.list.size();
    }

    @Override
    public Sector getItem(int index) {
        return this.list.get(index);
    }

    @Override
    public long getItemId(int index) {
        return index;
    }

    @Override
    public View getView(int index, View convertView, ViewGroup parent) {
        LayoutInflater inflater = LayoutInflater.from(this.context);
        View view = inflater.inflate(R.layout.item_sector, parent, false);
        TextView tv = (TextView) view.findViewById(R.id.sector_name);
        tv.setText(this.list.get(index).getName());
        return view;
    }
}
