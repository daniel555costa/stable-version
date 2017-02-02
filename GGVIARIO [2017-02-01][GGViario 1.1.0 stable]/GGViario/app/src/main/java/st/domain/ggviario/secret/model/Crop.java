package st.domain.ggviario.secret.model;

import java.util.Date;

/**
 * Created by xdata on 12/25/16.
 */
public class Crop {

    private Date date;
    private int quantity;
    private int quantityPerca;
    private int quantityPercaGalinha;


    public Crop(Date date, int quantity, int quantityPerca, int quantityPercaGalinha) {
        this.date = date;
        this.quantity = quantity;
        this.quantityPerca = quantityPerca;
        this.quantityPercaGalinha = quantityPercaGalinha;
    }

    public Date getDate() {
        return date;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getQuantityPerca() {
        return quantityPerca;
    }

    public int getQuantityPercaGalinha() {
        return quantityPercaGalinha;
    }

    public boolean hasPerca() {
        return quantityPerca>0;
    }

    public boolean hasPercaGalinhas() {
        return quantityPercaGalinha>0;
    }
}
