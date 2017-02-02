package st.domain.ggviario.secret.dao;

import android.content.Context;
import android.support.annotation.NonNull;
import android.util.Log;

import com.db.chart.model.Point;

import java.util.Calendar;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;

import st.domain.ggviario.secret.model.Crop;
import st.domain.ggviario.secret.model.CropSector;
import st.domain.ggviario.secret.model.Sector;
import st.domain.ggviario.secret.model.User;
import st.domain.support.android.sql.OnCatchSQLRow;
import st.domain.support.android.sql.SQLRow;
import st.domain.support.android.sql.builder.Insert;
import st.domain.support.android.sql.sqlite.Convert;
import st.domain.support.android.sql.builder.Select;



/**
 *
 * Created by xdata on 12/24/16.
 */
public class DaoCrop  extends Dao {
    public DaoCrop(Context context) {
        super(context);
    }

    public void register(int quantity, Sector sector, int quantityPercasOvos, int quantityPercasGalinha) {

        User s = DaoUser.geUser(this.getContext());

        begin(Operaction.INSERT);

        insertInto(T_CROP$, T_CROP.crop_id)
                .columns(

                        T_CROP.crop_totalovos,
                        T_CROP.crop_sector_id,
                        T_CROP.crop_user_id,
                        T_CROP.crop_percasovos,
                        T_CROP.crop_percasgalinhas
                ).values(

                        quantity,
                        sector.getId(),
                        s.getId(),
                        quantityPercasOvos,
                        quantityPercasGalinha
        );
        execute();
        end();

        Log.i("GGVIARIO@INFO", "last row id is" + getResources().last_insert_rowid()+"");

        end();

        super.cloneDatabase();
    }

    public List<Crop> loadCropData(){

        final List<Crop> cropList = new Stack<>();

        query().execute(new Select(ALL)
                .from(VER_CROPGROUP$)
        );

        query().forLoopCursor(new OnCatchSQLRow() {
            @Override
            public void accept(SQLRow row) {
                cropList.add(mountCropDate(row));
            }
        });

        return cropList;
    }

    public  List<CropSector> loadCropContents(final Date date){

        final List<CropSector> contentsList = new LinkedList<>();

        query().execute(
                new Select(ALL)
                    .from(VER_CROPSECTORDATE$)
                    .where(VER_CROPSECTORDATE.date).equal(Convert.date(date))
        );

        query().forLoopCursor(new OnCatchSQLRow() {
            @Override
            public void accept(SQLRow row) {
                contentsList.add(mountDateSector(row));
            }
        });


        query().execute();

        return contentsList;
    }

    static CropSector mountDateSector(SQLRow row) {
        return new CropSector(
                row.date(VER_CROPGROUP.date),
                row.integer(VER_CROPGROUP.quantity),
                row.integer(VER_CROPGROUP.quantitypercas),
                row.integer(VER_CROPGROUP.quantitypercasgalinha),
                DaoSector.mountSector(row)
        );
    }

    @NonNull
    public static Crop mountCropDate(SQLRow row) {
        return new Crop(

                row.date(VER_CROPGROUP.date),
                row.integer(VER_CROPGROUP.quantity),
                row.integer(VER_CROPGROUP.quantitypercas),
                row.integer(VER_CROPGROUP.quantitypercasgalinha)

        );
    }

    public List<Point> reportCropSector(Integer id, final ReportType type) {
        final LinkedList<Point> points = new LinkedList<>();

        //strftime('%Y-%m-%d'

        Select sumSector = (Select) new Select(sum(T_CROP.crop_totalovos))
                .from(T_CROP$)
                .where(strftime("%Y-%m-%d", column(T_CROP.crop_dtreg))).equal(column(VER_CROP_DATE.date));
        if(id != null)
            sumSector.and(T_CROP.crop_sector_id).equal(value(id));


        query().execute(
                select(VER_CROP_DATE.date,
                        sumSector.as("sum")
                        )
                .from(VER_CROP_DATE$)
        );

        query().forLoopCursor(new OnCatchSQLRow() {
            @Override
            public void accept(SQLRow row) {
                Date date = row.date(VER_CROP_DATE.date);
                Calendar calendar = Calendar.getInstance();
                calendar.setTime(date);
                String label;

                /*
                SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, and SATURDAY.
                 */

                Map<Integer, String> map = new LinkedHashMap<>();
                map.put(Calendar.SUNDAY, "Dom"); //Domingo
                map.put(Calendar.MONDAY, "Seg"); //Segunda
                map.put(Calendar.TUESDAY, "Ter"); //Terca
                map.put(Calendar.WEDNESDAY, "Qua"); //Quarta
                map.put(Calendar.THURSDAY, "Qui"); //Qunita
                map.put(Calendar.FRIDAY, "Sex"); //Sexta
                map.put(Calendar.SATURDAY, "Sab"); //Dabado

                if(type == ReportType.MONTH)
                    label = String.valueOf(calendar.get(Calendar.DAY_OF_MONTH));
                else {
                    label = String.valueOf(map.get(calendar.get(Calendar.DAY_OF_WEEK)));
                }
                if(row.real("sum") != null)
                    points.add(new Point(label, row.real("sum")));
            }
        });

        return points;
    }


    public enum  ReportType {
        MONTH,
        WEEK
    }
}
