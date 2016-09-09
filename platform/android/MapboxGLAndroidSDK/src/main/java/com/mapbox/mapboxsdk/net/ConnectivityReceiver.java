package com.mapbox.mapboxsdk.net;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.util.Log;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Listens for Connectivity changes
 */
public class ConnectivityReceiver extends BroadcastReceiver {
    private static final String TAG = ConnectivityReceiver.class.getSimpleName();
    private static ConnectivityReceiver INSTANCE;

    public static synchronized ConnectivityReceiver instance(Context context) {
        if (INSTANCE == null) {
            //Register new instance
            INSTANCE = new ConnectivityReceiver();
            context.registerReceiver(INSTANCE, new IntentFilter("android.net.conn.CONNECTIVITY_CHANGE"));

            //Add default listeners
            INSTANCE.addListener(new NativeConnectivityListener());
        }

        return INSTANCE;
    }

    private List<ConnectivityListener> listeners = new CopyOnWriteArrayList<>();


    private ConnectivityReceiver() {
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        boolean connected = isConnected(context);
        Log.v(TAG, "Connected: " + connected);

        //Loop over listeners
        for (ConnectivityListener listener : listeners) {
            listener.onNetworkStateChanged(connected);
        }
    }

    public void addListener(ConnectivityListener listener) {
        listeners.add(listener);
    }

    public boolean isConnected(Context context) {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        return (activeNetwork != null && activeNetwork.isConnected());
    }

}
