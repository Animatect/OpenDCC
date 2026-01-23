# Findqtadvanceddocking.cmake
# Finds or builds Qt Advanced Docking System for Qt5
#
# This module will define:
#   qtadvanceddocking_FOUND - system has qtadvanceddocking
#   ads::qtadvanceddocking - imported target

include(FetchContent)

# First try to find an existing installation
find_path(
    QTADS_INCLUDE_DIR
    NAMES DockManager.h
    PATH_SUFFIXES ads
    PATHS
        "${CMAKE_PREFIX_PATH}/include"
        "${QTADS_ROOT}/include"
        "$ENV{QTADS_ROOT}/include"
)

find_library(
    QTADS_LIBRARY
    NAMES qtadvanceddocking qtadvanceddocking-qt5 ads
    PATHS
        "${CMAKE_PREFIX_PATH}/lib"
        "${QTADS_ROOT}/lib"
        "$ENV{QTADS_ROOT}/lib"
)

if(QTADS_INCLUDE_DIR AND QTADS_LIBRARY)
    message(STATUS "Found qtadvanceddocking: ${QTADS_LIBRARY}")

    if(NOT TARGET ads::qtadvanceddocking)
        add_library(ads::qtadvanceddocking UNKNOWN IMPORTED)
        set_target_properties(ads::qtadvanceddocking PROPERTIES
            IMPORTED_LOCATION "${QTADS_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${QTADS_INCLUDE_DIR}"
        )
        target_link_libraries(ads::qtadvanceddocking INTERFACE
            Qt5::Core Qt5::Gui Qt5::Widgets
        )
    endif()

    set(qtadvanceddocking_FOUND TRUE)
else()
    message(STATUS "qtadvanceddocking not found, building from source...")

    FetchContent_Declare(
        qtadvanceddocking_src
        GIT_REPOSITORY https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git
        GIT_TAG 4.3.1
        GIT_SHALLOW TRUE
    )

    # Configure build options - force Qt5 since OpenDCC uses Qt5
    set(ADS_VERSION "4.3.1" CACHE STRING "" FORCE)
    set(BUILD_STATIC OFF CACHE BOOL "" FORCE)
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(QT_VERSION_MAJOR 5 CACHE STRING "" FORCE)

    FetchContent_MakeAvailable(qtadvanceddocking_src)

    # The library creates target names based on Qt version: qt${QT_VERSION_MAJOR}advanceddocking
    # Also creates an alias: ads::qt${QT_VERSION_MAJOR}advanceddocking
    # Targets are created in the src subdirectory
    if(NOT TARGET ads::qtadvanceddocking)
        if(TARGET ads::qt5advanceddocking)
            # The library already provides this alias, just create our standard alias
            add_library(ads::qtadvanceddocking ALIAS qt5advanceddocking)
        elseif(TARGET qt5advanceddocking)
            add_library(ads::qtadvanceddocking ALIAS qt5advanceddocking)
        elseif(TARGET qtadvanceddocking)
            add_library(ads::qtadvanceddocking ALIAS qtadvanceddocking)
        elseif(TARGET ads)
            add_library(ads::qtadvanceddocking ALIAS ads)
        else()
            # Debug: list available targets in src subdirectory where they're actually created
            if(EXISTS "${qtadvanceddocking_src_SOURCE_DIR}/src")
                get_property(_targets DIRECTORY "${qtadvanceddocking_src_SOURCE_DIR}/src" PROPERTY BUILDSYSTEM_TARGETS)
                message(STATUS "Available targets in qtadvanceddocking_src/src: ${_targets}")
            endif()
            message(FATAL_ERROR "Qt Advanced Docking System was fetched but no known target was created. "
                               "Expected qt5advanceddocking target. Source dir: ${qtadvanceddocking_src_SOURCE_DIR}")
        endif()
    endif()

    set(qtadvanceddocking_FOUND TRUE)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(qtadvanceddocking DEFAULT_MSG qtadvanceddocking_FOUND)
