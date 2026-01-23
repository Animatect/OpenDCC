# Simple module to find USD.

# can use either ${USD_ROOT}, or ${USD_CONFIG_FILE} (which should be ${USD_ROOT}/pxrConfig.cmake) to find USD, defined
# as either Cmake var or env var
if(NOT DEFINED HOUDINI_ROOT AND NOT DEFINED ENV{HOUDINI_ROOT})
    message(FATAL_ERROR "HOUDINI_ROOT is not defined")
endif()

find_path(
    USD_INCLUDE_DIR pxr/pxr.h
    PATHS ${HOUDINI_ROOT}/toolkit/include $ENV{HOUDINI_ROOT}/include
    DOC "USD Include directory"
    NO_DEFAULT_PATH)

if(WIN32)
    find_path(
        USD_LIBRARY_DIR libpxr_usd.lib
        PATHS ${HOUDINI_ROOT}/custom/houdini/dsolib $ENV{HOUDINI_ROOT}/custom/houdini/dsolib
        DOC "USD Libraries directory")
elseif(UNIX)
    find_path(
        USD_LIBRARY_DIR libpxr_usd.so libusd.dylib
        PATHS ${HOUDINI_ROOT}/custom/houdini/dsolib $ENV{HOUDINI_ROOT}/custom/houdini/dsolib ${HOUDINI_ROOT}/dsolib
              $ENV{HOUDINI_ROOT}/dsolib
        DOC "USD Libraries directory"
        NO_DEFAULT_PATH)
endif()

if(DEFINED HOUDINI_ROOT)
    set(HOUDINI_BIN "${HOUDINI_ROOT}/bin")
else()
    set(HOUDINI_BIN "$ENV{HOUDINI_ROOT}/bin")
endif()

find_program(
    USD_GENSCHEMA_SCRIPT
    NAMES usdGenSchema usdGenSchema.py
    PATHS ${HOUDINI_BIN}
    DOC "USD Gen schema application" REQUIRED
    NO_DEFAULT_PATH)

set(_run_usd_gen_schema ${USD_GENSCHEMA_SCRIPT})

get_filename_component(USD_GENSCHEMA_DIR ${USD_GENSCHEMA_SCRIPT} DIRECTORY)

# Find Houdini's Python executable for usdGenSchema
# Houdini 20.x uses python311/, python39/, python37/ directories
find_program(
    _houdini_python_exe
    NAMES python python.exe
    PATHS
        "${HOUDINI_ROOT}/python311"
        "${HOUDINI_ROOT}/python39"
        "${HOUDINI_ROOT}/python37"
        "${HOUDINI_ROOT}/python/bin"
        "${HOUDINI_ROOT}/bin"
    NO_DEFAULT_PATH)

if(_houdini_python_exe)
    list(PREPEND _run_usd_gen_schema "${_houdini_python_exe}")
elseif(PYTHON_EXECUTABLE)
    list(PREPEND _run_usd_gen_schema "${PYTHON_EXECUTABLE}")
else()
    # Fallback to system python
    find_program(_fallback_python NAMES python3 python)
    if(_fallback_python)
        list(PREPEND _run_usd_gen_schema "${_fallback_python}")
    endif()
endif()

set(USD_GENSCHEMA
    ${_run_usd_gen_schema}
    CACHE STRING "" FORCE)

if(USD_INCLUDE_DIR AND EXISTS "${USD_INCLUDE_DIR}/pxr/pxr.h")
    foreach(_usd_comp MAJOR MINOR PATCH)
        file(STRINGS "${USD_INCLUDE_DIR}/pxr/pxr.h" _usd_tmp REGEX "#define PXR_${_usd_comp}_VERSION .*$")
        string(REGEX MATCHALL "[0-9]+" USD_${_usd_comp}_VERSION ${_usd_tmp})
    endforeach()
    file(STRINGS "${USD_INCLUDE_DIR}/pxr/pxr.h" _usd_tmp REGEX "#define PXR_VERSION .*$")
    string(REGEX MATCHALL "[0-9]+" USD_PXR_VERSION ${_usd_tmp})
    set(USD_PXR_VERSION
        ${USD_PXR_VERSION}
        CACHE INTERNAL "" FORCE)
    set(USD_VERSION
        ${USD_MAJOR_VERSION}.${USD_MINOR_VERSION}.${USD_PATCH_VERSION}
        CACHE INTERNAL "USD version" FORCE)
endif()

# find python version which houdini uses
if(WIN32)
    set(_hboost_lib_dir "${HOUDINI_ROOT}/bin")
else()
    set(_hboost_lib_dir "${HOUDINI_ROOT}/dsolib")
endif()
file(
    GLOB _hboost_python_lib_list
    RELATIVE ${_hboost_lib_dir}
    ${_hboost_lib_dir}/*hboost_python*${CMAKE_SHARED_LIBRARY_SUFFIX})
if(NOT _hboost_python_lib_list)
    message(FATAL_ERROR "Failed to find hboost_python library.")
endif()

list(GET _hboost_python_lib_list 0 _hboost_python_lib)
# Handle both 2-digit (e.g., python39) and 3-digit (e.g., python311) version numbers
string(REGEX REPLACE ".*hboost_python([0-9]+)-.*" "\\1" _python_ver ${_hboost_python_lib})
string(SUBSTRING ${_python_ver} 0 1 _python_major_ver)
string(SUBSTRING ${_python_ver} 1 -1 _python_minor_ver)
message(STATUS "Detected Houdini Python version: ${_python_major_ver}.${_python_minor_ver} (${_python_ver})")

# Set USD_PYTHON_DIR to Houdini's Python site-packages where pxr modules are located
# This is used by MakeTargets.cmake for USD schema generation
set(USD_PYTHON_DIR "${HOUDINI_ROOT}/python${_python_ver}/lib/site-packages"
    CACHE PATH "USD Python modules directory" FORCE)
message(STATUS "Houdini USD Python modules: ${USD_PYTHON_DIR}")

add_library(_houdini_deps INTERFACE)

set(_houdini_libs
    OpenImageIO_sidefx;hboost_filesystem-mt-x64;hboost_iostreams-mt-x64;hboost_system-mt-x64;hboost_regex-mt-x64;hboost_python${_python_ver}-mt-x64
)
foreach(_houdini_lib ${_houdini_libs})
    find_library(
        ${_houdini_lib}_path
        NAMES ${_houdini_lib}
        PATHS ${HOUDINI_ROOT}/dsolib ${HOUDINI_ROOT}/custom/houdini/dsolib/ REQUIRED
        NO_DEFAULT_PATH)

    message(STATUS "Found ${_houdini_lib}: ${${_houdini_lib}_path}")

    target_link_libraries(_houdini_deps INTERFACE ${${_houdini_lib}_path})
endforeach()

# Set Boost_PYTHON_LIBRARY for targets that use ${Boost_PYTHON_LIBRARY} directly
set(Boost_PYTHON_LIBRARY "${hboost_python${_python_ver}-mt-x64_path}" CACHE FILEPATH "Boost Python library (hboost for Houdini)" FORCE)
message(STATUS "Set Boost_PYTHON_LIBRARY to: ${Boost_PYTHON_LIBRARY}")

# Set OIIO variables that FindOpenImageIO would normally set
# This ensures targets using ${OIIO_OpenImageIO_LIBRARY} get the Houdini sidefx version
# Find both OIIO sidefx libraries
find_library(_houdini_oiio_util_lib NAMES OpenImageIO_Util_sidefx PATHS "${HOUDINI_ROOT}/custom/houdini/dsolib" NO_DEFAULT_PATH REQUIRED)
set(OIIO_OpenImageIO_LIBRARY "${OpenImageIO_sidefx_path}" CACHE FILEPATH "OpenImageIO library (sidefx for Houdini)" FORCE)
set(OIIO_OpenImageIO_Util_LIBRARY "${_houdini_oiio_util_lib}" CACHE FILEPATH "OpenImageIO_Util library (sidefx for Houdini)" FORCE)
set(OIIO_INCLUDE_DIR "${HOUDINI_ROOT}/toolkit/include" CACHE PATH "OpenImageIO include directory" FORCE)
set(OIIO_INCLUDE_DIRS "${OIIO_INCLUDE_DIR}" CACHE PATH "OpenImageIO include directories" FORCE)
set(OIIO_LIBRARIES "${OpenImageIO_sidefx_path};${_houdini_oiio_util_lib}" CACHE STRING "OpenImageIO libraries" FORCE)
message(STATUS "Set OIIO_OpenImageIO_LIBRARY to: ${OIIO_OpenImageIO_LIBRARY}")
message(STATUS "Set OIIO_OpenImageIO_Util_LIBRARY to: ${OIIO_OpenImageIO_Util_LIBRARY}")

# Set TBB variables to use Houdini's TBB
find_library(_houdini_tbb_lib NAMES tbb PATHS "${HOUDINI_ROOT}/custom/houdini/dsolib" NO_DEFAULT_PATH REQUIRED)
find_library(_houdini_tbbmalloc_lib NAMES tbbmalloc PATHS "${HOUDINI_ROOT}/custom/houdini/dsolib" NO_DEFAULT_PATH REQUIRED)
set(TBB_tbb_LIBRARY_RELEASE "${_houdini_tbb_lib}" CACHE FILEPATH "TBB library (Houdini)" FORCE)
set(TBB_tbbmalloc_LIBRARY_RELEASE "${_houdini_tbbmalloc_lib}" CACHE FILEPATH "TBB malloc library (Houdini)" FORCE)
set(TBB_LIBRARIES "${_houdini_tbb_lib};${_houdini_tbbmalloc_lib}" CACHE STRING "TBB libraries (Houdini)" FORCE)
message(STATUS "Set TBB_tbb_LIBRARY_RELEASE to: ${TBB_tbb_LIBRARY_RELEASE}")

# Set Imath variables to use Houdini's Imath_sidefx
find_library(_houdini_imath_lib NAMES Imath_sidefx PATHS "${HOUDINI_ROOT}/custom/houdini/dsolib" NO_DEFAULT_PATH REQUIRED)
set(Imath_LIBRARY "${_houdini_imath_lib}" CACHE FILEPATH "Imath library (Houdini sidefx)" FORCE)
message(STATUS "Set Imath_LIBRARY to: ${Imath_LIBRARY}")

find_library(
    _houdini_python_lib
    NAMES python${_python_ver} python${_python_major_ver}.${_python_minor_ver}
          python${_python_major_ver}.${_python_minor_ver}m python
    PATHS "${HOUDINI_ROOT}/python${_python_ver}/libs" "${HOUDINI_ROOT}/python/libs" "${HOUDINI_ROOT}/python/lib"
          REQUIRED
    NO_DEFAULT_PATH)

find_path(
    _houdini_python_include_dir
    NAMES pyconfig.h
    PATHS "${HOUDINI_ROOT}/python${_python_ver}/include" "${HOUDINI_ROOT}/python/include"
          "${HOUDINI_ROOT}/python/include/python${_python_major_ver}.${_python_minor_ver}"
          "${HOUDINI_ROOT}/python/include/python${_python_major_ver}.${_python_minor_ver}m" REQUIRED
    NO_DEFAULT_PATH)

target_link_libraries(_houdini_deps INTERFACE ${_houdini_python_lib})
target_include_directories(_houdini_deps INTERFACE "${_houdini_python_include_dir}")

# Set Python variables so find_package(PythonInterp/PythonLibs) use Houdini's Python
find_program(_houdini_python_executable
    NAMES python python${_python_major_ver}.${_python_minor_ver} python${_python_ver}
    PATHS "${HOUDINI_ROOT}/python${_python_ver}" "${HOUDINI_ROOT}/python"
    NO_DEFAULT_PATH
    REQUIRED)
set(PYTHON_EXECUTABLE "${_houdini_python_executable}" CACHE FILEPATH "Python interpreter (Houdini)" FORCE)
set(PYTHON_LIBRARY "${_houdini_python_lib}" CACHE FILEPATH "Python library (Houdini)" FORCE)
set(PYTHON_INCLUDE_DIR "${_houdini_python_include_dir}" CACHE PATH "Python include directory (Houdini)" FORCE)
set(PYTHON_INCLUDE_DIRS "${_houdini_python_include_dir}" CACHE PATH "Python include directories (Houdini)" FORCE)
message(STATUS "Set PYTHON_EXECUTABLE to: ${PYTHON_EXECUTABLE}")

# USD library list - updated for Houdini 20.5+ (USD 24.x)
# Note: Library names vary between USD versions and Houdini builds
set(_houdini_pxr_libs
    ar;arch;cameraUtil;garch;geomUtil;gf;glf;hd;hdGp;hdMtlx;hdsi;hdSt;hdx;hf;hgi;hgiGL;hgiInterop;hio;js;kind;ndr;pcp;plug;pxOsd;sdf;sdr;tf;trace;ts;usd;usdAppUtils;usdBakeMtlx;usdGeom;usdHydra;usdImaging;usdImagingGL;usdLux;usdMedia;usdMtlx;usdPhysics;usdProc;usdProcImaging;usdRender;usdRi;usdRiPxrImaging;usdShade;usdSkel;usdSkelImaging;usdUI;usdUtils;usdviewq;usdVol;usdVolImaging;vt;work;
)
foreach(_pxr_lib ${_houdini_pxr_libs})
    find_library(
        ${_pxr_lib}_path
        NAMES libpxr_${_pxr_lib} pxr_${_pxr_lib}
        PATHS ${HOUDINI_ROOT}/custom/houdini/dsolib/ ${HOUDINI_ROOT}/dsolib/ REQUIRED
        NO_DEFAULT_PATH)
    add_library(${_pxr_lib} SHARED IMPORTED)

    set_target_properties(
        ${_pxr_lib}
        PROPERTIES INTERFACE_COMPILE_DEFINITIONS "PXR_PYTHON_ENABLED=1"
                   INTERFACE_INCLUDE_DIRECTORIES "${USD_INCLUDE_DIR}"
                   INTERFACE_LINK_LIBRARIES _houdini_deps
                   IMPORTED_IMPLIB "${${_pxr_lib}_path}"
                   IMPORTED_LOCATION "${${_pxr_lib}_path}")
endforeach()

foreach(_pxr_lib ${_houdini_pxr_libs})
    target_link_libraries(${_pxr_lib} INTERFACE ${_houdini_pxr_libs})
endforeach()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    USD
    REQUIRED_VARS USD_INCLUDE_DIR USD_LIBRARY_DIR USD_GENSCHEMA USD_PXR_VERSION
    VERSION_VAR USD_VERSION)
