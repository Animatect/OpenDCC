opendcc_make_library(
    compositing
    TYPE
    SHARED
    PUBLIC_HEADERS
    api.h
    compositor.h
    frame_info.h
    layer.h
    CPPFILES
    compositor.cpp
    frame_info.cpp
    VS_FOLDER
    usd/dcc
    PRIVATE_DEFINITIONS
    OPENDCC_COMPOSITING_EXPORT
    LIBRARY_DEPENDENCIES
    usdImagingGL
    usdImaging
    tf)

# MSVC's conformant preprocessor (/Zc:preprocessor) has issues with USD's
# TF_DECLARE_PUBLIC_TOKENS macros used in hgi/tokens.h. Disable for this target.
if(MSVC AND DCC_HOUDINI_SUPPORT)
    set_target_properties(compositing PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
    # Remove /Zc:preprocessor and use traditional preprocessor for this target
    get_target_property(_compile_options compositing COMPILE_OPTIONS)
    if(_compile_options)
        list(REMOVE_ITEM _compile_options "/Zc:preprocessor")
        set_target_properties(compositing PROPERTIES COMPILE_OPTIONS "${_compile_options}")
    endif()
    target_compile_options(compositing PRIVATE /Zc:preprocessor-)
endif()
