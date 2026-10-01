# SPDX-FileCopyrightText: 2017 Nextcloud GmbH and Nextcloud contributors
# SPDX-FileCopyrightText: 2012 ownCloud GmbH
# SPDX-License-Identifier: GPL-2.0-or-later

#
# Sigma Grid Cloud custom build
#

set( APPLICATION_NAME       "Sigma Grid Cloud" )
set( APPLICATION_SHORTNAME  "SigmaGridCloud" )
set( APPLICATION_EXECUTABLE "sigmagridcloud" )
set( APPLICATION_ICON_NAME  "${APPLICATION_SHORTNAME}" )

set( APPLICATION_CONFIG_NAME "${APPLICATION_EXECUTABLE}" )
set( APPLICATION_DOMAIN     "sigmagrid.hr" )
set( APPLICATION_VENDOR     "Sigma Grid" )

# Disable the official Nextcloud updater for the custom build.
# We will define our own update mechanism later.
set( APPLICATION_UPDATE_URL "" CACHE STRING "URL for updater" )
set( APPLICATION_HELP_URL   "https://sigmagrid.hr" CACHE STRING "URL for the help menu" )

# Default macOS builds (Nextcloud + NextcloudDev) use the Icon Composer (.icon)
# format for the app icon. That format can only be compiled by a recent enough
# toolchain (Xcode 26 ships the actool that understands .icon, and macOS 26
# provides the matching SDK), so we gate the modern pipeline on the build
# environment. Older environments — and branded customer builds, which use a
# different APPLICATION_NAME and ship their own colourful icon SVG — fall back
# to the historical Inkscape + ECM (ecm_add_app_icon) .icns pipeline instead.
#
# The Xcode/actool version is the real capability gate; the macOS check is a
# coarse secondary guard. Detection runs every configure and is intentionally
# NOT cached, so the decision self-heals once the build host is upgraded without
# requiring a clean reconfigure. Pass -DMACOS_USE_ICON_COMPOSER=ON/OFF to
# override auto-detection entirely.
if(APPLE)
    execute_process(COMMAND sw_vers -productVersion
        OUTPUT_VARIABLE _macos_product_version RESULT_VARIABLE _macos_ver_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process(COMMAND xcodebuild -version
        OUTPUT_VARIABLE _xcodebuild_version_raw RESULT_VARIABLE _xcode_ver_result
        OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

    set(MACOS_ICON_COMPOSER_TOOLCHAIN_SUPPORTED OFF)
    if(_macos_ver_result EQUAL 0 AND _xcode_ver_result EQUAL 0)
        string(REGEX MATCH "Xcode ([0-9]+\\.[0-9]+)" _ "${_xcodebuild_version_raw}")
        set(_xcode_version "${CMAKE_MATCH_1}")
        message(STATUS "Detected build environment: macOS ${_macos_product_version}, Xcode ${_xcode_version}")
        if(_macos_product_version VERSION_GREATER_EQUAL "26.5"
           AND _xcode_version VERSION_GREATER_EQUAL "26.5")
            set(MACOS_ICON_COMPOSER_TOOLCHAIN_SUPPORTED ON)
        endif()
    endif()

    if(NOT DEFINED MACOS_USE_ICON_COMPOSER)
        if((APPLICATION_NAME STREQUAL "Nextcloud" OR NEXTCLOUD_DEV)
           AND EXISTS "${CMAKE_SOURCE_DIR}/theme/colored/AppIcon.icon/icon.json"
           AND MACOS_ICON_COMPOSER_TOOLCHAIN_SUPPORTED)
            set(MACOS_USE_ICON_COMPOSER ON)
            message(STATUS "Using Icon Composer (.icon) format for the macOS app icon.")
        else()
            set(MACOS_USE_ICON_COMPOSER OFF)
        endif()
    endif()

    if(NOT MACOS_USE_ICON_COMPOSER)
        message(STATUS "macOS app icon: using legacy ECM .icns pipeline.")
        if((APPLICATION_NAME STREQUAL "Nextcloud" OR NEXTCLOUD_DEV)
           AND EXISTS "${CMAKE_SOURCE_DIR}/theme/colored/Nextcloud-macOS-icon.svg")
            set(APPLICATION_ICON_NAME "Nextcloud-macOS")
            message(STATUS "Using macOS-specific application icon: ${APPLICATION_ICON_NAME}")
        endif()
    endif()
endif()

set( APPLICATION_ICON_SET "SVG" )

# Sigma Grid Cloud server
set(
    APPLICATION_SERVER_URL
    "https://cloud.sigmagrid.hr"
    CACHE STRING
    "URL for the server to use. If entered, the UI field will be pre-filled with it"
)

# The client may only connect to the Sigma Grid Cloud server.
set( APPLICATION_SERVER_URL_ENFORCE ON )

set( APPLICATION_REV_DOMAIN "hr.sigmagrid.cloud" )
set( APPLICATION_REV_DOMAIN_DBUS "cloud.sigmagrid.hr" )

set( DEVELOPMENT_TEAM "NKUJUXUJ3B" CACHE STRING "Apple Development Team ID" )

set(
    APPLICATION_VIRTUALFILE_SUFFIX
    "sigmagridcloud"
    CACHE STRING
    "Virtual file suffix (not including the .)"
)

set( APPLICATION_OCSP_STAPLING_ENABLED OFF )
set( APPLICATION_FORBID_BAD_SSL OFF )

set( LINUX_PACKAGE_SHORTNAME "sigmagridcloud" )
set( LINUX_APPLICATION_ID "${APPLICATION_REV_DOMAIN}.${LINUX_PACKAGE_SHORTNAME}")

set( THEME_CLASS "NextcloudTheme" )
set( WIN_SETUP_BITMAP_PATH "${CMAKE_SOURCE_DIR}/admin/win/nsi" )

set(
    MAC_INSTALLER_BACKGROUND_FILE
    "${CMAKE_SOURCE_DIR}/admin/osx/installer-background.png"
    CACHE STRING
    "The MacOSX installer background image"
)

# set( THEME_INCLUDE          "${OEM_THEME_DIR}/mytheme.h" )
# set( APPLICATION_LICENSE    "${OEM_THEME_DIR}/license.txt )

## Updater options

# Do not use Nextcloud's official update infrastructure for Sigma Grid Cloud.
option( BUILD_UPDATER "Build updater" OFF )

option( WITH_PROVIDERS "Build with providers list" ON )

option(
    ENFORCE_VIRTUAL_FILES_SYNC_FOLDER
    "Enforce use of virtual files sync folder when available"
    OFF
)

option(
    DISABLE_VIRTUAL_FILES_SYNC_FOLDER
    "Disable use of virtual files sync folder even when available"
    OFF
)

option(
    ENFORCE_SINGLE_ACCOUNT
    "Enforce use of a single account in desktop client"
    OFF
)

option(
    DO_NOT_USE_PROXY
    "Do not use system wide proxy, instead always do a direct connection to server"
    OFF
)

option(
    WIN_DISABLE_USERNAME_PREFILL
    "Do not prefill the Windows user name when creating a new account"
    OFF
)

## Theming options

set(
    NEXTCLOUD_BACKGROUND_COLOR
    "#0082c9"
    CACHE STRING
    "Default Nextcloud background color"
)

set(
    APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR
    ${NEXTCLOUD_BACKGROUND_COLOR}
    CACHE STRING
    "Hex color of the wizard header background"
)

set(
    APPLICATION_WIZARD_HEADER_TITLE_COLOR
    "#ffffff"
    CACHE STRING
    "Hex color of the text in the wizard header"
)

option(
    APPLICATION_WIZARD_USE_CUSTOM_LOGO
    "Use the logo from ':/client/theme/colored/wizard_logo.(png|svg)' else the default application icon is used"
    ON
)

#
## Windows Shell Extensions & MSI
## Sigma Grid Cloud uses its own GUIDs so it can coexist with Nextcloud.
#

if(WIN32)

    # Context Menu
    set(
        WIN_SHELLEXT_CONTEXT_MENU_GUID
        "{C24140CA-8D8B-4B61-BC92-854EBEE24FA6}"
    )

    # Overlays
    set(
        WIN_SHELLEXT_OVERLAY_GUID_ERROR
        "{06E4550B-858A-44CE-BD15-8B3B51F7B73C}"
    )

    set(
        WIN_SHELLEXT_OVERLAY_GUID_OK
        "{EE82E3F0-E576-4070-A42C-34C84454B72A}"
    )

    set(
        WIN_SHELLEXT_OVERLAY_GUID_OK_SHARED
        "{4CCBBF11-F117-4B7D-88C7-8BE4872FB30A}"
    )

    set(
        WIN_SHELLEXT_OVERLAY_GUID_SYNC
        "{39E264F1-C2AF-46CF-81A0-2D78BA1E2BB1}"
    )

    set(
        WIN_SHELLEXT_OVERLAY_GUID_WARNING
        "{04BC8A82-52AA-4BA4-A85C-61EFA15A65FB}"
    )

    # MSI Upgrade Code (without brackets)
    set(
        WIN_MSI_UPGRADE_CODE
        "3AF87248-F41D-42FC-940C-C5F46EC593C5"
    )

    # Windows build options
    option( BUILD_WIN_MSI "Build MSI scripts and helper DLL" OFF )
    option( BUILD_WIN_TOOLS "Build Win32 migration tools" OFF )

endif()

if (APPLE AND CMAKE_OSX_DEPLOYMENT_TARGET VERSION_GREATER_EQUAL 11.0)
    option(
        BUILD_FILE_PROVIDER_MODULE
        "Build the macOS virtual files File Provider module"
        OFF
    )
endif()
