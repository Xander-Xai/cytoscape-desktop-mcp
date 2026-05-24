package edu.ucsd.idekerlab.cytoscapemcp;

import java.util.Dictionary;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.Before;
import org.junit.Test;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.osgi.framework.ServiceRegistration;

import org.cytoscape.command.AvailableCommands;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests verifying that CyActivator correctly initializes whether Cytoscape fires
 * AppsFinishedStartingEvent (fresh boot) or the desktop is already running (dynamic install).
 */
public class CyActivatorInitTest {

    /**
     * Subclass that overrides doInitializeApp() to avoid real OSGi/Swing dependencies while still
     * exercising the real guard logic in initializeApp().
     *
     * <p>Uses constructor injection ({@link
     * CyActivator#CyActivator(CyActivator.CxServiceTrackerFactory)}) with a factory that calls
     * {@link #initializeApp()} synchronously — no live OSGi runtime needed. The {@link
     * AtomicReference} self-reference pattern avoids the chicken-and-egg problem of passing {@code
     * this} before the object is fully constructed.
     */
    static class TestableCyActivator extends CyActivator {
        final AtomicInteger realInitCount = new AtomicInteger(0);

        private TestableCyActivator(CxServiceTrackerFactory factory) {
            super(factory);
        }

        /**
         * Creates a {@link TestableCyActivator} whose injected factory calls {@link
         * #initializeApp()} immediately, simulating a dynamic install where the CX reader service
         * is already registered when the tracker is opened.
         */
        static TestableCyActivator create() {
            AtomicReference<TestableCyActivator> selfRef = new AtomicReference<>();
            TestableCyActivator a =
                    new TestableCyActivator(
                            (bc, filter) -> {
                                selfRef.get().initializeApp();
                                return null; // no real tracker needed in tests
                            });
            selfRef.set(a);
            return a;
        }

        @Override
        void doInitializeApp() {
            realInitCount.incrementAndGet();
        }
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    private BundleContext mockBundleContext(boolean availableCommandsPresent) {
        BundleContext bc = mock(BundleContext.class);
        // AbstractCyActivator.registerService calls bc.registerService internally — silence it.
        when(bc.registerService(anyString(), any(), any(Dictionary.class)))
                .thenReturn(mock(ServiceRegistration.class));
        when(bc.registerService(any(String[].class), any(), any(Dictionary.class)))
                .thenReturn(mock(ServiceRegistration.class));
        ServiceReference ref = availableCommandsPresent ? mock(ServiceReference.class) : null;
        when(bc.getServiceReference(AvailableCommands.class)).thenReturn(ref);
        return bc;
    }

    private TestableCyActivator activator;

    @Before
    public void setUp() {
        activator = TestableCyActivator.create();
    }

    @Test
    public void start_freshBoot_doesNotInitializeBeforeEventFires() throws Exception {
        activator.start(mockBundleContext(false));
        assertEquals(
                "should not init until AppsFinishedStartingEvent fires",
                0,
                activator.realInitCount.get());
    }

    @Test
    public void start_dynamicInstall_initializesImmediately() throws Exception {
        activator.start(mockBundleContext(true));
        assertEquals(
                "should init when CX reader service tracker fires on dynamic install",
                1,
                activator.realInitCount.get());
    }

    @Test
    public void initializeApp_idempotent_multipleCallsRunRealInitOnce() {
        activator.initializeApp();
        activator.initializeApp();
        activator.initializeApp();
        assertEquals(
                "doInitializeApp should execute exactly once regardless of call count",
                1,
                activator.realInitCount.get());
    }

    @Test
    public void start_bothPathsTrigger_initializesExactlyOnce() throws Exception {
        // Simulate race: AvailableCommands present (tracker fires) AND listener fires too.
        activator.start(mockBundleContext(true)); // tracker path
        activator.initializeApp(); // listener path (fires again)
        assertEquals(
                "real init should run only once even if both trigger paths fire",
                1,
                activator.realInitCount.get());
    }
}
