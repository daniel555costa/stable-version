package st.domain.ggviario.secret.references;

import st.domain.support.android.text.XFieldName;

/**
 * Created by xdata on 7/25/16.
 * Essa classe serve para mapear todos dos Objectos dos banco do daod
 */
public class RData implements XFieldName
{
    public static final String ALL="*";
    public static  String VER_CLIENTS;


    //VIEWS
    public static String //Currenr arra as view
            VER_METREAGE_PRODUCT,
            VER_PRODUTO_SELL,
            VER_CURRENT_LOGIN,
            VER_CLIEN_NEWS,
            VER_PRODUCT_COMPLETE // The data of product table jand measure table
                    ;


    //ATRIBUTOS PARA A ENTIDATE CLIENTE
    public static String
            T_CLIENT,
            CLI_NAME,
            CLI_SURNAME,
            CLI_OBJ_RESID,
            CLI_CONTACT,
            CLI_PREVIEWID,
            CLI_ID;

    //ATRIBUTOS PARA A ENTIDADE MEDIDA
    public static String
            MET_NAME,
            MET_COD,
            MET_ID;

    //Entidade produto
    public static String
            PROD_ID,
            PROD_NAME;

    public static String
            SELL_PROD_ID,
            SELL_QUANTITY,
            SELL_PRICE,
            SELL_MET_ID
                    ;
    public static String VER_SELLROULE;

    public  static String T_CONVERSION,
            CONV_ID,
            CONV_MET_ID1,
            CONV_MET_ID2,
            CONV_VALUE1,
            CONV_VALUE2;

    public static  String T_OBJECT,
            OBJ_ID,
            OBJ_PREVIEWID,
            OBJ_TOBJ_ID,
            OBJ_DESC,
            OBJ_USER_ID;


    public static String T_USER,
            USER_NAME,
            USER_ID,
            USER_SURNAME,
            USER_ACCESSNAME;

    public static String  T_LOGIN,
            LOG_ID,
            LOG_USER_ID,
            LOG_STATE,
            LOG_DTREG;

    public static String T_TYPEREQUEST,
            TREQ_ID,
            TREQ_DESC;

    public static String T_REQUEST,
            REQ_PREVIEWID,
            REQ_ID,
            REQ_CLI_ID,
            REQ_PROD_ID,
            REQ_MET_ID,
            REQ_USER_ID,
            REQ_QUANTITY,
            REQ_BASEQUANTITY,
            REQ_MONTPAYMENT,
            REQ_TREQ_ID,
            REQ_DTENTREGA,
            REQ_DTPAGAR,
            REQ_DTREG,
    /**
     * Estado da requisicao
     * 1 - Siguifica que a requisicao aninda nao foi enviada para o servidor
     * 2 - Singuificad que ja foi e enviada e esta espera de uma reesposta do sevidor
     * 0 - Sigunifica que a requiscao foi enidada para o servidor e a resposta esta valida
     */
    REQ_STATE,
            VREQ_STATEDESC;
}
