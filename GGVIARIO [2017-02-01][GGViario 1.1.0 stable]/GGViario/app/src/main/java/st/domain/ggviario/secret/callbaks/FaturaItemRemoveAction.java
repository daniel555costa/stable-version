package st.domain.ggviario.secret.callbaks;

import st.domain.ggviario.secret.adapter.FaturaItemAdapter;

/**
 * Created by xdata on 12/21/16.
 */

public interface FaturaItemRemoveAction extends Action <FaturaItemAdapter.ItemDataSet> {
    public void accept(FaturaItemAdapter.ItemDataSet e);
}
