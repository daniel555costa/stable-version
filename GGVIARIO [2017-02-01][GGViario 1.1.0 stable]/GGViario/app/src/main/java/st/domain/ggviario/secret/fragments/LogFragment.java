package st.domain.ggviario.secret.fragments;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.StaggeredGridLayoutManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;

import st.domain.ggviario.secret.CropContent;
import st.domain.ggviario.secret.R;
import st.domain.ggviario.secret.adapter.CropAdapter;
import st.domain.ggviario.secret.dao.DaoCrop;
import st.domain.ggviario.secret.model.Crop;
import st.domain.ggviario.secret.references.RMap;

/**
 *
 * Created by dchost on 30/01/17.
 */

public class LogFragment extends Fragment{

    private Context context;
    private  boolean log = true;

    public void setLog(boolean log) {
        this.log = log;
    }

    @Override
    public void onAttach(Context context) {
        if(log) Log.i("APP.GGVIARIO", "-> "+ name() +".onAttach(Context)");
        super.onAttach(context);
        this.context = context;
    }

    @Override
    public void onAttach(Activity activity) {
        if(log) Log.i("APP.GGVIARIO", "-> " + name() + ".onAttach(Activity)");
        super.onAttach(activity);
    }

    @Override
    public Context getContext() {
        return context;
    }

    private String name() {
        return this.getClass().getSimpleName();
    }


    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        if(log) Log.i("APP.GGVIARIO", "-> " +name() + ".onCreateView");
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onCreate");
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onViewCreated(View view, @Nullable Bundle savedInstanceState) {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onViewCreated");
        super.onViewCreated(view, savedInstanceState);
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onActivityCreated");
        super.onActivityCreated(savedInstanceState);
    }

    @Override
    public void onResume() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onResume");
        super.onResume();
    }

    @Override
    public void onDestroy() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onDestroy");
        super.onDestroy();
    }

    @Override
    public void onDestroyView() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onDestroyView");
        super.onDestroyView();
    }

    @Override
    public void onDestroyOptionsMenu() {
        if(log) Log.i("APP.GGVIARIO", "-> " +name() + ".onDestroyOptionsMenu");
        super.onDestroyOptionsMenu();
    }

    @Override
    public void onDetach() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onDetach");
        super.onDetach();
    }

    @Override
    public void onPause() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onPause");
        super.onPause();
    }

    @Override
    public void onStop() {
        Log.i("APP.GGVIARIO", "-> " +name() + ".onStop");
        super.onStop();
    }

    @Override
    public void onStart() {
        if(log)  Log.i("APP.GGVIARIO", "-> " +name() + ".onStart");
        super.onStart();
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        if(log) Log.i("APP.GGVIARIO", "-> " +name() + ".onSaveInstanceState");
        super.onSaveInstanceState(outState);
    }

    protected void info(String infoMessage){
        Log.i("APP.GGVIARIO", infoMessage);
    }

    protected void error(String errorMessage) {
        Log.e("APP.GGVIARIO", errorMessage);
    }

    protected void waring(String waringMessage) {
        Log.w("APP.GGVIARIO", waringMessage);
    }

    protected void verbose(String waringMessage) {
        Log.v("APP.GGVIARIO", waringMessage);
    }

}
