package st.domain.ggviario.secret.model;

import st.domain.ggviario.secret.dao.Dao;

/**
 * Created by xdata on 12/24/16.
 */
public class Sector implements Dao.T_SECTOR {
    private Integer id;
    private String name;

    public Sector(Integer id, String name) {
        this.id = id;
        this.name = name;
    }

    public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }
}
