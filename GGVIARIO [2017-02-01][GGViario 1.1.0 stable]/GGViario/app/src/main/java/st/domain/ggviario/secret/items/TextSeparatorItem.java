package st.domain.ggviario.secret.items;

import android.content.Context;
import android.view.View;
import android.widget.TextView;

import st.domain.ggviario.secret.R;
import st.domain.support.android.adapter.ItemDataSet;
import st.domain.support.android.adapter.ItemViewHolder;
import st.domain.support.android.adapter.RecyclerViewAdapter;

/**
 *
 * Created by xdata on 12/25/16.
 */

public class TextSeparatorItem {

    public static RecyclerViewAdapter.ViewHolderFactory factoryInstance() {
        return new RecyclerViewAdapter.ViewHolderFactory() {
            @Override
            public ItemViewHolder factory(View view) {
                return new TextSeparatorViewHolder(view);
            }
        };
    }

    public  static class TextSeparatorDataSet implements ItemDataSet {

        private int mLayoutId;
        private  int mLayoutTextViewId;

        private ValueType mTextType;
        private Integer mTextId = null;
        private String mText = null;

        private ValueType mTextColorType;
        private Integer mTextColor;

        private ValueType mBackgroundType;
        private Integer background;

        public TextSeparatorDataSet(String text) {
            this.mText = text;
            this.mLayoutId = R.layout.item_textseparator;
            this.mLayoutTextViewId = R.id.tv_text_separator;
        }

        public TextSeparatorDataSet(int idText) {
            this(null);
            this.mTextId = idText;
        }

        public void setContonLayout(int mLayoutId, int layoutTextViewId) {
            this.mLayoutId = mLayoutId;
            this.mLayoutTextViewId = layoutTextViewId;
        }

        public String getText() {
            return mText;
        }

        public Integer getTextId() {
            return this.mTextId;
        }

        public int getLayoutId() {
            return this.mLayoutId;
        }

        public void setTextColor(Integer color) {
            this.mTextColor = color;
            this.mTextColorType = ValueType.RESOURCES;
        }

        public void setTextColorId(Integer textColorId) {
            this.mTextColor = textColorId;
            this.mTextColorType = ValueType.VALUE;
        }
    }

    private static class TextSeparatorViewHolder extends ItemViewHolder{

        private TextSeparatorDataSet dataSet;
        private Context context;

        TextSeparatorViewHolder(View itemView) {
            super(itemView);
            this.context = this.itemView.getContext();
        }

        public void bind(ItemDataSet dataSet) {
            TextView tvText = (TextView) itemView.findViewById(R.id.tv_text_separator);
            this.dataSet = (TextSeparatorDataSet) dataSet;
            tvText.setText(getText());

            Integer textColor = getTextColor();
            if(textColor != null)
                tvText.setTextColor(textColor);

        }

        private String getText () {
            if(this.dataSet.mTextId != null && dataSet.getText() == null)
                return this.itemView.getContext().getString(this.dataSet.getTextId());
            else return this.dataSet.mText;
        }

        private Integer getTextColor( ) {
            if(this.dataSet.mTextColorType == ValueType.RESOURCES) return this.context.getResources().getColor(this.dataSet.mTextColor);
            if(this.dataSet.mTextColorType == ValueType.VALUE) return this.dataSet.mTextColor;
            return null;
        }
    }

    private enum ValueType {
        RESOURCES,
        VALUE
    }
}
