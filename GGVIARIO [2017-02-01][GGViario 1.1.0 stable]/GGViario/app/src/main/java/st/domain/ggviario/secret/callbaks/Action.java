package st.domain.ggviario.secret.callbaks;

/**
 *
 * Created by xdata on 12/21/16.
 */

public interface Action <E> {
    void accept( E e );
}
