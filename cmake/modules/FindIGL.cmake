set(IGL_ROOT
    ""
    CACHE PATH "IGL_ROOT")

find_path(
    IGL_INCLUDE_DIR igl/igl_inline.h
    PATHS "${IGL_ROOT}/include" "${IGL_ROOT}"
    DOC "libigl include path")

if(NOT IGL::igl)
    add_library(IGL::igl INTERFACE IMPORTED)
    target_include_directories(IGL::igl INTERFACE "${IGL_INCLUDE_DIR}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(IGL DEFAULT_MSG IGL_INCLUDE_DIR)
