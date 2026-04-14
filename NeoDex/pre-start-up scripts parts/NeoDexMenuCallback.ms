/*
    NeoDexMenuCallback.ms
    
    Refactored as Struct for better encapsulation and maintainability.
    Handles registration of the NeoDex menu in the 3ds Max menu bar.
    
    Menu structure:
        NeoDex
        ├── NeoDex Exporter
        ├── NeoDex Importer
        ├── ─────────────────
        ├── NeoDex Manager
        ├── Extra Tools ►
        │   ├── Keyframe Optimizer
        │   └── Cell Shade Creator
        ├── Settings...
        ├── ─────────────────
        └── About...
    
    Usage:
        ::NeoDexMenu.register()
*/

-- ============================================================================
-- MAIN MENU STRUCT
-- ============================================================================

struct NeoDexMenuStruct
(
    -- ============================================================================
    -- MENU GUIDS (unique identifiers for menu items)
    -- ============================================================================
    
    private menuGUID       = "14AACE63-4B4A-4D24-B0DC-CE7BE8039887",
    private exporterGUID   = "49C3AD2F-56E6-4FD7-BA75-C37DBE46F561",
    private importerGUID   = "2C130A42-9564-45C9-88B3-B4DFEAE2F583",
    private separator1GUID = "997EB101-2553-4AF0-B4E6-24D42AE680C8",
    private managerGUID    = "0C915529-C664-4849-A718-0BEE8D9DD2FB",
    private extraToolsGUID = "E1A2B3C4-5D6E-7F80-9102-A3B4C5D6E7F8",
    private kfOptimizerGUID = "F2B3C4D5-6E7F-8091-A2B3-C4D5E6F70819",
    private cellShadeGUID   = "A3C4D5E6-7F80-9102-B3C4-D5E6F7081920",
    private settingsGUID   = "B5C8D2E1-3F97-4A5B-8D16-9F4E6C7A2B03",
    private separator2GUID = "A7F83B12-6E41-4C9A-B2D5-8F1E3A7C9D04",
    private aboutGUID      = "D3B7E5A1-2F84-4C6E-9A13-7E2D5B8F4C01",
    
    private actionTableId = 647394,
    
    -- ============================================================================
    -- MENU CONSTRUCTION
    -- ============================================================================
    
    -- Callback function invoked by 3ds Max menu system
    public fn menuCallback =
    (
        local menuMgr = callbacks.notificationParam()
        local mainMenuBar = menuMgr.mainMenuBar
        local neoDexMainMenu = mainMenuBar.CreateSubMenu "14AACE63-4B4A-4D24-B0DC-CE7BE8039887" "NeoDex"
        
        neoDexMainMenu.CreateAction "49C3AD2F-56E6-4FD7-BA75-C37DBE46F561" 647394 "NeoDex_Exporter`NeoDex Toolkit"
        neoDexMainMenu.CreateAction "2C130A42-9564-45C9-88B3-B4DFEAE2F583" 647394 "NeoDex_Importer`NeoDex Toolkit"
        neoDexMainMenu.CreateSeparator "997EB101-2553-4AF0-B4E6-24D42AE680C8"
        neoDexMainMenu.CreateAction "0C915529-C664-4849-A718-0BEE8D9DD2FB" 647394 "NeoDex_Manager`NeoDex Toolkit"
        
        -- Extra Tools Submenu
        local extraMenu = neoDexMainMenu.CreateSubMenu "E1A2B3C4-5D6E-7F80-9102-A3B4C5D6E7F8" "Extra Tools"
        extraMenu.CreateAction "F2B3C4D5-6E7F-8091-A2B3-C4D5E6F70819" 647394 "NeoDex_KeyframeOptimizer`NeoDex Toolkit"
        extraMenu.CreateAction "A3C4D5E6-7F80-9102-B3C4-D5E6F7081920" 647394 "NeoDex_CellShadeCreator`NeoDex Toolkit"
        
        neoDexMainMenu.CreateAction "B5C8D2E1-3F97-4A5B-8D16-9F4E6C7A2B03" 647394 "NeoDex_Settings`NeoDex Toolkit"
        neoDexMainMenu.CreateSeparator "A7F83B12-6E41-4C9A-B2D5-8F1E3A7C9D04"
        neoDexMainMenu.CreateAction "D3B7E5A1-2F84-4C6E-9A13-7E2D5B8F4C01" 647394 "NeoDex_About`NeoDex Toolkit"
    ),
    
    -- ============================================================================
    -- REGISTRATION
    -- ============================================================================
    
    -- Register the NeoDex menu callback with 3ds Max
    public fn register =
    (
        callbacks.removeScripts id:#NeoDex
        callbacks.addScript #cuiRegisterMenus "::NeoDexMenu.menuCallback()" id:#NeoDex
    )
)

-- ============================================================================
-- GLOBAL INSTANCE & AUTO-REGISTRATION
-- ============================================================================

global NeoDexMenu = NeoDexMenuStruct()
::NeoDexMenu.register()
