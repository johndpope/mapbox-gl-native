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
            INSTANCE = new ConnectivityReceiver(context);
            context.registerReceiver(INSTANCE, new IntentFilter("android.net.conn.CONNECTIVITY_CHANGE"));

            //Add default listeners
            INSTANCE.addListener(new NativeConnectivityListener());
        }

        return INSTANCE;
    }

    private final Context context;
    private List<WeakReference<ConnectivityListener>> listeners = new CopyOnWriteArrayList<>();


    private ConnectivityReceiver(Context context) {
        this.context = context;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        boolean connected = isConnected();
        Log.v(TAG, "Connected: " + connected);

        //Loop over listeners, collecting stale references as we go
        List<WeakReference<ConnectivityListener>> removals = new ArrayList<>();
        for (WeakReference<ConnectivityListener> ref : listeners) {
            ConnectivityListener listener = ref.get();
            if (listener != null) {
                listener.onNetworkStateChanged(connected);
            } else {
                removals.add(ref);
            }
        }

        //Cleanup
        listeners.removeAll(removals);
    }

    public void addListener(ConnectivityListener listener) {
        listeners.add(new WeakReference<>(listener));
    }

    public boolean isConnected() {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        return (activeNetwork != null && activeNetwork.isConnected());
    }

}
