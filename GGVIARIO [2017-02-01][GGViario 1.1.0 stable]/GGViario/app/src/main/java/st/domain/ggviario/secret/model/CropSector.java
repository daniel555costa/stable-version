package st.domain.ggviario.secret.model;

import java.util.Date;

/**
 * Created by xdata on 12/29/16.
 */

public class CropSector extends Crop {

    private final Sector sector;

    public CropSector(Date date, int quantity, int quantityPerca, int quantityPercaGalinha, Sector sector) {
        super(date, quantity, quantityPerca, quantityPercaGalinha);
        this.sector = sector;
    }

    public Sector getSector() {
        return sector;
    }
}
