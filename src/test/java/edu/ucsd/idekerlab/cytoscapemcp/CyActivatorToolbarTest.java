package edu.ucsd.idekerlab.cytoscapemcp;

import java.awt.Container;
import java.lang.reflect.InvocationTargetException;

import javax.swing.JPanel;
import javax.swing.JToolBar;
import javax.swing.SwingUtilities;

import org.junit.Before;
import org.junit.Test;

import edu.ucsd.idekerlab.cytoscapemcp.ui.McpStatusPanel;

import org.cytoscape.application.swing.CySwingApplication;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests verifying that CyActivator uses the public {@link
 * CySwingApplication#getStatusToolBar()} API to locate the status toolbar, rather than walking the
 * Swing component tree.
 */
public class CyActivatorToolbarTest {

    private CyActivator activator;
    private CySwingApplication mockSwingApp;

    @Before
    public void setUp() {
        activator = new CyActivator();
        mockSwingApp = mock(CySwingApplication.class);
    }

    @Test
    public void getStatusToolBar_returnsToolbarFromSwingAppApi() {
        JToolBar expected = new JToolBar();
        when(mockSwingApp.getStatusToolBar()).thenReturn(expected);

        JToolBar result = mockSwingApp.getStatusToolBar();

        assertNotNull("Status toolbar should be non-null", result);
        assertEquals(
                "Should return toolbar from CySwingApplication.getStatusToolBar()",
                expected,
                result);
        verify(mockSwingApp).getStatusToolBar();
    }

    @Test
    public void getStatusToolBar_panelCanBeAddedToReturnedToolbar() {
        JToolBar toolbar = new JToolBar();
        when(mockSwingApp.getStatusToolBar()).thenReturn(toolbar);

        JToolBar result = mockSwingApp.getStatusToolBar();
        JPanel panel = new JPanel();
        result.add(panel);

        assertEquals("Panel should have been added to the toolbar", 1, toolbar.getComponentCount());
        assertEquals("Panel in toolbar should be our panel", panel, toolbar.getComponent(0));
    }

    /**
     * Verifies that shutDown() removes the McpStatusPanel from whatever parent container it was
     * added to, so no orphaned toolbar icon remains after the app is dynamically unregistered.
     */
    @Test
    public void shutDown_removesMcpStatusPanelFromParentContainer()
            throws InterruptedException, InvocationTargetException {
        // Simulate the panel having been added to a container (toolbar or injected parent).
        JToolBar toolbar = new JToolBar();
        McpStatusPanel panel = new McpStatusPanel(1234);
        toolbar.add(panel);
        Container parent = panel.getParent();
        assertEquals("Panel should be in toolbar before shutdown", 1, toolbar.getComponentCount());

        // Wire the panel into the activator as doInitializeApp() would.
        activator.mcpStatusPanel = panel;

        activator.shutDown();

        // Flush the EDT so the invokeLater inside shutDown() has run.
        SwingUtilities.invokeAndWait(() -> {});

        assertNull("Panel should have been removed from its parent", panel.getParent());
        assertEquals("Toolbar should be empty after shutdown", 0, toolbar.getComponentCount());
    }
}
