package st.domain.ggviario.secret;

import android.content.DialogInterface;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.design.widget.FloatingActionButton;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;

import com.wdullaer.materialdatetimepicker.date.DatePickerDialog;

import java.util.Calendar;
import java.util.Hashtable;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import st.domain.ggviario.secret.adapter.FaturaAdapter;
import st.domain.ggviario.secret.callbaks.BackHomeUpMenuObserver;
import st.domain.ggviario.secret.callbaks.MenuMapper;


/**
 *
 * Created by xdata on 12/21/16.
 */

public class Despesas extends AppCompatActivity implements DatePickerDialog.OnDateSetListener, DialogInterface.OnCancelListener {
    private RecyclerView listFaturaRecycler;
    private FaturaAdapter adapter;
    private FloatingActionButton floatAdd;
    private EditText edDateDespesa;
    private Calendar dateDespesa;
    private Toolbar toolbar;
    private MenuMapper menuMaper;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
        super.setContentView(R.layout._despesa);

        this.edDateDespesa = (EditText) findViewById(R.id.ed_despesa_date);
        this.floatAdd = (FloatingActionButton) findViewById(R.id.bt_new_despesa);
        this.toolbar = (Toolbar) findViewById(R.id.toolbar);
        this.menuMaper = new MenuMapper(this);

        this.floatAdd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                adapter.add();
            }
        });

        View.OnClickListener openCalendarAction = new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                pickerDate();
            }
        };

        this.edDateDespesa.setOnClickListener(openCalendarAction);


        prepareToolbar();

        this.menuMaper.add(new BackHomeUpMenuObserver());
        this.dateDespesa  = Calendar.getInstance();

        this.listFaturaRecycler = (RecyclerView) findViewById(R.id.rv_fatura_list);
        LinearLayoutManager llm = new LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false);
        this.listFaturaRecycler.setLayoutManager(llm);

        this.adapter = new FaturaAdapter(this);
        this.listFaturaRecycler.setAdapter(this.adapter);
        this.adapter.add();

    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_despesa, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return this.menuMaper.menuAction(item);
    }

    private void prepareToolbar()
    {
        this.toolbar.setTitle("Despesa");
        this.toolbar.inflateMenu(R.menu.menu_despesa);

        this.setSupportActionBar(toolbar);
        if(this.getSupportActionBar() != null)
        {
            this.getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            this.getSupportActionBar().setTitle("Despesa");
            this.toolbar.setTitleTextColor(getResources().getColor(R.color.white));
        }
    }


    private void pickerDate()
    {
        DatePickerDialog datePickerDialog = DatePickerDialog.newInstance(
                this,
                dateDespesa.get(Calendar.YEAR),
                dateDespesa.get(Calendar.MONTH),
                dateDespesa.get(Calendar.DAY_OF_MONTH)
        );

        Calendar currentDate = Calendar.getInstance();
        Calendar pastMinDate = Calendar.getInstance();

        int intervalDay = 23*59*59*999;

        pastMinDate.setTimeInMillis( pastMinDate.getTimeInMillis() - intervalDay*10);

//        datePickerDialog.setMinDate( pastMinDate );
        datePickerDialog.setMaxDate(currentDate);


        //List de dias validos

        List<Calendar> avalibleListDay = new LinkedList<>();
        Calendar aux = Calendar.getInstance();

        while (aux.getTimeInMillis() <= currentDate.getTimeInMillis())
        {
            if(aux.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY) {

                Calendar date = Calendar.getInstance();
                date.setTimeInMillis(aux.getTimeInMillis());
                avalibleListDay.add(date);
            }
            aux.setTimeInMillis(aux.getTimeInMillis() + 24 * 60 * 60 * 1000);
        }

        Calendar selectableDays [] = new Calendar[ avalibleListDay.size() ];
        int iCount =0;
        for(Calendar date: avalibleListDay)
            selectableDays[iCount++] = date;

//        datePickerDialog.setSelectableDays(selectableDays);
        datePickerDialog.setOnCancelListener(this);
        datePickerDialog.show( getFragmentManager(), "DatePickerDialog" );


        // 63545040000000
    }


    @Override
    public void onDateSet(DatePickerDialog view, int year, int monthOfYear, int dayOfMonth) {

        Map<Integer, String> mapMonth = new Hashtable<>();
        mapMonth.put(0,  getString(R.string.javier));
        mapMonth.put(1,  getString(R.string.febray));
        mapMonth.put(2,  getString(R.string.marc));
        mapMonth.put(3,  getString(R.string.april));
        mapMonth.put(4,  getString(R.string.may));
        mapMonth.put(5,  getString(R.string.june));
        mapMonth.put(6,  getString(R.string.julhe));
        mapMonth.put(7,  getString(R.string.agust));
        mapMonth.put(8,  getString(R.string.septeber));
        mapMonth.put(9,  getString(R.string.octobre));
        mapMonth.put(10, getString(R.string.november));
        mapMonth.put(11, getString(R.string.december));


        this.dateDespesa.set(year, monthOfYear, dayOfMonth);
        String  dateText = dayOfMonth + " de "+ mapMonth.get(monthOfYear)+ " de "+year;
        this.edDateDespesa.setText(dateText);
    }

    @Override
    public void onCancel(DialogInterface dialog) {
        this.dateDespesa = Calendar.getInstance();
    }
}
