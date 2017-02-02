package st.domain.ggviario.secret.dao;

import android.content.Context;

import st.domain.ggviario.secret.model.User;

/**
 *
 * Created by xdata on 7/26/16.
 */
public class DaoUser extends Dao
{


    public DaoUser(Context context) {
        super(context);
    }

    public void login (String username, String pwd) {
    }

    /**
     * Obter o utilizador logado
     * @return
     */
    public static User geUser(Context context)
    {
//        DaoUser daoUser = new DaoUser(context);
//
//        daoUser.begin(Operaction.SELECT);
//        daoUser.select(RData.ALL)
//                .from(RData.VER_CURRENT_LOGIN);
//        daoUser.execute();
//        ArrayList<LinkedHashMap<CharSequence, Object>> result = daoUser.getSelectResult();
//        daoUser.end();
//        if(result.size()>0)
//        {
//            int id = (int) result.get(0).get(RData.USER_ID);
//            String name = result.get(0).get(RData.USER_NAME).toString();
//            String surname = result.get(0).get(RData.USER_SURNAME).toString();
//            String accessName = result.get(0).get(RData.USER_ACCESSNAME).toString();
//            User logado = new User(id, name, surname, accessName);
//            return  logado;
//        }
//
//        return null;

        return new User(2, "Teste", "Teste", "test@test");
    }
}
