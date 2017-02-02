package st.domain.ggviario.secret.fragments;

import android.content.res.Configuration;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import st.domain.ggviario.secret.CropActivity;
import st.domain.ggviario.secret.Despesas;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.model.ItemFragment;
import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.references.RMap;
import st.domain.ggviario.secret.adapter.MainHomeAdapter;

import java.util.List;

//import ivb.com.materialstepper.stepperFragment;

/**
 *
 * Created by xdata on 8/11/16.
 */
public class MainHome extends Fragment
{
    private View rootView;
    private RecyclerView recyclerView;
    private MainHomeAdapter supportAdapter;
    private List<ItemDataSet> list;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        this.supportAdapter = new MainHomeAdapter(this.getContext());



        MainHomeAdapter.DataOperation harvest = MainHomeAdapter.newOperation()
                .color(R.color.mat_pink_primary)
                .name("Colheita")
                .image(R.drawable.ic_shopping_basket_white_48dp)
                .activity(CropActivity.class);


        MainHomeAdapter.DataOperation fatura = MainHomeAdapter.newOperation()
                .color(R.color.md_brown_500)
                .name("Despesa")
                .image(R.drawable.ic_content_paste_white_48dp)
                .activity(Despesas.class);


        this.supportAdapter.add(harvest);
        this.supportAdapter.add(fatura);

//        this.list.add(sell);
//        this.list.add(sync);
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        this.rootView = inflater.inflate(R.layout._main_home, container, false);
        this.recyclerView = (RecyclerView) rootView.findViewById(R.id.recycler_view);

//        final LinearLayoutManager layoutManager = new LinearLayoutManager(getActivity());
//        final GridLayoutManager layoutManager = new GridLayoutManager(getContext(), 2, LinearLayoutManager.VERTICAL, false);
        int columns = (this.getActivity().getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE)
                ? 3 : 2;

        final StaggeredGridLayoutManager layoutManager = new StaggeredGridLayoutManager(columns, LinearLayoutManager.VERTICAL);
        layoutManager.setGapStrategy(StaggeredGridLayoutManager.GAP_HANDLING_MOVE_ITEMS_BETWEEN_SPANS);

        this.recyclerView.setHasFixedSize(true);
        layoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int newState) {
                super.onScrollStateChanged(recyclerView, newState);

            }


            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                int lastCompletPosition = 0;
                int max = -1;
                int row[] = layoutManager.findLastCompletelyVisibleItemPositions(null);
                for (int i : row)
                    if (i > max) max = i;

//                lastCompletPosition = layoutManager.findLastCompletelyVisibleItemPosition() ;
//                lastCompletPosition = max;

                if (lastCompletPosition + 1 == supportAdapter.getItemCount()) {

                }
            }
        });

        this.recyclerView.setAdapter(this.supportAdapter);
        return this.rootView;
    }

//    @Override
//    public boolean onNextButtonHandler() {
//        return true;
//    }
}
