package st.domain.support.android.adapter;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;

import st.domain.support.android.model.ItemView;

import java.util.ArrayList;


public class ListAdapter extends BaseAdapter
{

	ArrayList<ItemView> listItems;
	private Context context;

	public ListAdapter(Context context)
	{
		this.listItems =  new ArrayList<ItemView>();
		this.context = context;
	}
	
	public ListAdapter()
	{
		this.listItems = new ArrayList<>();
	}
	
	public void setContext(Context context)
	{
		this.context = context;
	}
	
	@Override
	public int getCount() 
	{
		return listItems.size();
	}

	@Override
	public Object getItem(int position) 
	{
		return listItems.get(position).getObject();
	}

	@Override
	public long getItemId(int position) 
	{
		return position;
	}

	@Override
	public View getView(int position, View view, ViewGroup viewGroup) 
	{
		ItemView item = this.getItemView(position);
		Log.i("APP", "CONTEXT = "+context);
		LayoutInflater inflater = (LayoutInflater) this.context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		View itemView  = item.createView(position, inflater, view, viewGroup);
		return itemView;
	}

	public ItemView getItemView(int position)
	{
		return this.listItems.get(position);
	}


	public void addItem(ItemView item)
	{
		this.listItems.add(item);
	}
	
	public void removeItem(int index)
	{
		this.listItems.remove(index);
	}

	protected ArrayList<ItemView> getList()
	{

		return this.listItems;
	}

	public void addItems(ArrayList<? extends ItemView> metreages)
	{
		for(ItemView item: metreages)
			this.addItem(item);
	}

	public void clear()
	{
		this.listItems.clear();
	}

	public void replace(ArrayList<? extends ItemView> listData)
	{
		this.clear();
		this.addItems(listData);
	}

	public void moveItemTo(int indexItem, int newPosition)
	{
		ItemView itemMove = this.listItems.get(indexItem);
		this.listItems.remove(indexItem);
		this.listItems.add(newPosition, itemMove);
	}

	public void moveItemTo(ItemView item, int newPosition)
	{
		this.listItems.remove(item);
		this.listItems.add(newPosition, item);
	}

	public void addItem(int position, ItemView defaultClientView)
	{
		this.listItems.add(position, defaultClientView);
	}
}
