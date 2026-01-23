#ifdef OPENDCC_HOUDINI_SUPPORT

// Include TF preprocessor utilities first to ensure macros like TF_PP_CAT,
// _TF_PP_IFF_, etc. are defined before any other pxr headers use them.
// This is required for MSVC's conformant preprocessor (/Zc:preprocessor).
// Note: This is included here for precompiled header benefit, but individual
// source files that use TF_DECLARE_PUBLIC_TOKENS may need to include this
// directly before any pxr headers.
#include <pxr/base/tf/preprocessorUtilsLite.h>

namespace hboost
{
}
namespace boost = hboost;
#define BOOST_PYTHON_MODULE HBOOST_PYTHON_MODULE
#define BOOST_PYTHON_FUNCTION_OVERLOADS HBOOST_PYTHON_FUNCTION_OVERLOADS
#define BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS HBOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS
#endif