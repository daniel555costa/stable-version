package st.domain.ggviario.secret.dao;

import android.content.Context;

import java.util.LinkedList;
import java.util.List;

import st.domain.ggviario.secret.model.Sector;
import st.domain.support.android.sql.OnCatchSQLRow;
import st.domain.support.android.sql.SQLRow;
import st.domain.support.android.sql.builder.Select;

/**
 *
 * Created by xdata on 12/29/16.
 */

public class DaoSector extends Dao{

    public DaoSector(Context context) {
        super(context);
    }

    public List<Sector> loadSector () {

        final LinkedList<Sector> listSector = new LinkedList<Sector>();

        this.query().execute(
                new Select(ALL)
                    .from(T_SECTOR$)
        );

        this.query().forLoopCursor(
                new OnCatchSQLRow() {
                    @Override
                    public void accept(SQLRow row) {
                        listSector.add(mountSector(row));
                    }
                }
        );

        return listSector;
    }


    static Sector mountSector(SQLRow row) {
        return new Sector(row.integer(T_SECTOR.sector_id), row.string(T_SECTOR.sector_name));
    }
}
