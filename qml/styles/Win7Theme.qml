pragma Singleton
import QtQuick

// Windows 7 Aero Explorer visual constants
QtObject {
    // ── Fonts ──
    readonly property string fontFamily: "Segoe UI"
    readonly property int fontSizeSmall: 8
    readonly property int fontSizeNormal: 9
    readonly property int fontSizeMedium: 11
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeTitle: 17

    // ── Window Chrome ──
    readonly property color windowBackground: "#F0F0F0"
    readonly property color windowBorder: "#838383"

    // ── Navigation Bar ──
    readonly property color navBarGradientTop: "#FCFCFC"
    readonly property color navBarGradientBottom: "#E8ECF0"
    readonly property color navBarBorder: "#D2D5D8"

    // Nav buttons (Aero blue circular buttons)
    readonly property color navBtnNormal: "#3B72A9"
    readonly property color navBtnHover: "#4A8BC4"
    readonly property color navBtnPressed: "#2A5D8F"
    readonly property color navBtnDisabled: "#97B4CC"
    readonly property color navBtnArrow: "#FFFFFF"
    readonly property color navBtnBorder: "#1F4C74"
    readonly property color navBtnBorderDisabled: "#7A9AB5"
    readonly property color navBtnGloss: "#80FFFFFF"

    // ── Address Bar (Breadcrumbs) ──
    readonly property color addressBarBg: "#FFFFFF"
    readonly property color addressBarBorder: "#A7BECE"
    readonly property color addressBarBorderFocused: "#569BC7"
    readonly property color breadcrumbText: "#1E1E1E"
    readonly property color breadcrumbSeparator: "#969696"
    readonly property color breadcrumbHover: "#E4EEF8"
    readonly property color breadcrumbPressed: "#C4DCF0"

    // ── Search Box ──
    readonly property color searchBoxBg: "#FFFFFF"
    readonly property color searchBoxBorder: "#A7BECE"
    readonly property color searchBoxPlaceholder: "#969696"
    readonly property color searchBtnBg: "#5FA2D0"
    readonly property color searchBtnHover: "#72B4E0"

    // ── Command Bar ──
    readonly property color cmdBarGradientTop: "#F3F6F9"
    readonly property color cmdBarGradientBottom: "#DEE3E8"
    readonly property color cmdBarBorderTop: "#D0D4D9"
    readonly property color cmdBarBorderBottom: "#B8BFC7"
    readonly property color cmdBarText: "#1E1E1E"
    readonly property color cmdBarTextHover: "#1E1E1E"
    readonly property color cmdBarBtnHover: "#E4ECF5"
    readonly property color cmdBarBtnPressed: "#C8D6E5"
    readonly property color cmdBarSeparator: "#C8CDD2"

    // ── Navigation Panel (Left sidebar) ──
    readonly property color navPanelBg: "#FFFFFF"
    readonly property color navPanelBorder: "#D5DFE5"
    readonly property color navPanelHeaderText: "#3399FF"
    readonly property color navPanelItemText: "#1E1E1E"
    readonly property color navPanelItemHover: "#E6F0FA"
    readonly property color navPanelItemSelected: "#D8E6F2"
    readonly property color navPanelItemSelectedBorder: "#99CEFC"
    readonly property color navPanelExpandArrow: "#808080"
    readonly property int navPanelDefaultWidth: 220

    // ── Content Area ──
    readonly property color contentBg: "#FFFFFF"
    readonly property color contentBorder: "#D5DFE5"
    readonly property color contentHeaderBg: "#FFFFFF"
    readonly property color contentHeaderText: "#4D5F76"
    readonly property color contentHeaderBorder: "#E5E5E5"

    // Library header (the blue header at top of content area)
    readonly property color libraryHeaderText: "#0B3D6C"
    readonly property color librarySubText: "#5A6F84"

    // ── Item Selection ──
    readonly property color selectionBg: "#CCE8FF"
    readonly property color selectionBorder: "#99D1FF"
    readonly property color selectionHoverBg: "#E5F3FF"
    readonly property color selectionHoverBorder: "#70C0E7"
    readonly property color itemText: "#1E1E1E"
    readonly property color itemTextSecondary: "#717171"

    // ── Column Headers (Details view) ──
    readonly property color columnHeaderBg: "#FFFFFF"
    readonly property color columnHeaderHover: "#E8F0F8"
    readonly property color columnHeaderPressed: "#D0E0F0"
    readonly property color columnHeaderBorder: "#E5E5E5"
    readonly property color columnHeaderText: "#4D5F76"
    readonly property color columnSortArrow: "#717171"
    readonly property int columnHeaderHeight: 22

    // ── Details Panel (Bottom) ──
    readonly property color detailsPanelGradientTop: "#F2F6FB"
    readonly property color detailsPanelGradientBottom: "#EAF0F7"
    readonly property color detailsPanelBorder: "#D5DFE5"
    readonly property color detailsPanelText: "#1E1E1E"
    readonly property color detailsPanelLabel: "#717171"
    readonly property int detailsPanelHeight: 70

    // ── Status Bar ──
    readonly property color statusBarBg: "#ECF0F6"
    readonly property color statusBarBorder: "#D5DFE5"
    readonly property color statusBarText: "#5A5A5A"
    readonly property int statusBarHeight: 24

    // ── Scrollbar ──
    readonly property color scrollbarTrack: "#F0F0F0"
    readonly property color scrollbarHandle: "#C1C1C1"
    readonly property color scrollbarHandleHover: "#A8A8A8"
    readonly property color scrollbarHandlePressed: "#787878"

    // ── Context / Splitter ──
    readonly property color splitterColor: "#D5DFE5"
    readonly property int splitterWidth: 4

    // ── Spacing & Sizes ──
    readonly property int navBarHeight: 30
    readonly property int navBtnSize: 28
    readonly property int cmdBarHeight: 26
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeMedium: 48
    readonly property int iconSizeLarge: 96
    readonly property int iconSizeExtraLarge: 256
    readonly property int defaultMargin: 4
    readonly property int defaultPadding: 6
    readonly property int borderRadius: 2

    // ── Menu Bar (hidden by default) ──
    readonly property color menuBarBg: "#F0F0F0"
    readonly property color menuBarText: "#1E1E1E"
    readonly property color menuBarHover: "#91C9F7"
    readonly property color menuBarBorder: "#D5DFE5"
    readonly property int menuBarHeight: 20
}
