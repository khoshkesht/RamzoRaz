package com.mokho.ramzoraz.adivery;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import com.adivery.sdk.Adivery;
import com.adivery.sdk.AdiveryListener;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/** All SDK state is confined to the Android UI thread. No Controller is retained. */
public final class AdiveryPlugin extends GodotPlugin {
    private static final String TAG = "RamzoRazAdivery";
    private static final AtomicInteger NEXT_TOKEN = new AtomicInteger();
    private static String configuredAppId;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private String placement;
    private boolean initialized;
    private volatile boolean destroyed;
    private boolean resumed;
    private volatile boolean logging;
    private volatile Session session;

    private static final class Session {
        final int token;
        final long deadline = SystemClock.elapsedRealtime() + 30000;
        boolean submitted;
        boolean shown;
        boolean expired;
        Session(int token) { this.token = token; }
    }

    public AdiveryPlugin(Godot godot) { super(godot); }

    @Override public String getPluginName() { return TAG; }

    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("ad_event", String.class, Integer.class));
    }

    private void event(String kind, int token) {
        if (!destroyed) emitSignal("ad_event", kind, token);
    }

    private boolean liveActivity() {
        Activity activity = getActivity();
        return !destroyed && resumed && activity != null && !activity.isFinishing() && !activity.isDestroyed();
    }

    @UsedByGodot public void initialize(String appId, String placementId, boolean debugLogging) {
        ui.post(() -> {
            if (destroyed || initialized) return;
            Activity activity = getActivity();
            if (activity == null || appId.isEmpty() || placementId.isEmpty()) return;
            try {
                synchronized (AdiveryPlugin.class) {
                    if (configuredAppId != null && !configuredAppId.equals(appId)) {
                        Log.e(TAG, "A different app ID is already configured in this process.");
                        return;
                    }
                    logging = debugLogging;
                    Adivery.setLoggingEnabled(debugLogging);
                    if (configuredAppId == null) {
                        Adivery.configure(activity.getApplication(), appId);
                        configuredAppId = appId;
                    }
                }
                placement = placementId;
                Adivery.addPlacementListener(placement, listener);
                Adivery.prepareRewardedAd(activity, placement);
                initialized = true;
            } catch (RuntimeException error) {
                Log.e(TAG, "Cannot initialize rewarded ads", error);
                if (placement != null) Adivery.removePlacementListener(placement);
            }
        });
    }

    // Returning a process-wide token lets Godot retain the original request/level IDs.
    @UsedByGodot public int reserve_rewarded() {
        int token = NEXT_TOKEN.incrementAndGet();
        ui.post(() -> {
            if (!initialized || !liveActivity() || session != null) {
                event("unavailable", token);
                event("released", token);
                return;
            }
            try {
                if (!Adivery.isLoaded(placement)) {
                    event("unavailable", token);
                    event("released", token);
                    return;
                }
                Session next = new Session(token);
                session = next;
                event("ready", token);
                ui.postDelayed(() -> expire(next), 30000);
            } catch (RuntimeException error) {
                Log.e(TAG, "Cannot reserve rewarded ad", error);
                event("failed", token);
            }
        });
        return token;
    }

    @UsedByGodot public void show_rewarded(int token) {
        ui.post(() -> {
            Session current = session;
            if (current == null || current.token != token || current.submitted || current.expired) return;
            if (SystemClock.elapsedRealtime() >= current.deadline || !liveActivity()) {
                finish(current, "unavailable");
                return;
            }
            try {
                if (!Adivery.isLoaded(placement)) {
                    finish(current, "unavailable");
                    return;
                }
                current.submitted = true;
                Adivery.showAd(placement);
            } catch (RuntimeException error) {
                // The SDK may already have scheduled a display: quarantine until a terminal callback.
                Log.e(TAG, "Cannot show rewarded ad", error);
                current.expired = true;
                event("failed", current.token);
            }
        });
    }

    @UsedByGodot public void cancel_rewarded(int token) {
        ui.post(() -> {
            if (session != null && session.token == token && !session.shown) expire(session);
        });
    }

    private void expire(Session current) {
        if (session != current || current.shown || current.expired) return;
        current.expired = true;
        event("unavailable", current.token);
        // Once showAd was called, its callbacks have no SDK request ID. Never reuse the slot
        // until its closed callback arrives, even after the game's 30-second timeout.
        if (!current.submitted) {
            session = null;
            event("released", current.token);
        }
    }

    private void finish(Session current, String kind) {
        if (session != current) return;
        session = null;
        event(kind, current.token);
        event("released", current.token);
    }

    private final AdiveryListener listener = new AdiveryListener() {
        @Override public void onRewardedAdShown(String placementId) {
            Session callbackSession = session;
            ui.post(() -> {
                Session current = callbackSession;
                if (!placementId.equals(placement) || current == null || session != current || !current.submitted || current.expired || current.shown) return;
                if (SystemClock.elapsedRealtime() >= current.deadline) {
                    expire(current);
                    return;
                }
                current.shown = true;
                event("opened", current.token);
            });
        }

        @Override public void onRewardedAdClosed(String placementId, boolean isRewarded) {
            Session callbackSession = session;
            ui.post(() -> {
                Session current = callbackSession;
                if (!placementId.equals(placement) || current == null || session != current || !current.submitted) return;
                if (!current.expired && current.shown && isRewarded) event("rewarded", current.token);
                finish(current, "closed");
            });
        }

        @Override public void log(String placementId, String message) {
            // SDK 4.9.0 exposes log(), not the onError() in the newer online guide.
            // A mediation network can fail while another network has a loaded ad.
            if (logging) Log.d(TAG, "Network diagnostic for " + placementId + ": " + message);
        }
    };

    @Override public void onMainResume() { resumed = true; }
    @Override public void onMainPause() { resumed = false; }

    @Override public void onMainDestroy() {
        destroyed = true;
        resumed = false;
        ui.removeCallbacksAndMessages(null);
        if (placement != null) Adivery.removePlacementListener(placement);
        session = null;
    }
}
