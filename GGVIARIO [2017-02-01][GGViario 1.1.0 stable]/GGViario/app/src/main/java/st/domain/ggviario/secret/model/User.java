package st.domain.ggviario.secret.model;

/**
 * Created by xdata on 7/26/16.
 */
public class User
{
    private int id;
    private String name;
    private String surName;
    private String accesName;

    public User(int id, String name, String surName, String accesName) {
        this.id = id;
        this.name = name;
        this.surName = surName;
        this.accesName = accesName;
    }


    public int getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getSurName() {
        return surName;
    }

    public String getAccesName() {
        return accesName;
    }
}
