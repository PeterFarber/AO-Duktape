#ifdef __cplusplus
  #include "lua.hpp"
#else
  #include "lua.h"
  #include "lualib.h"
  #include "lauxlib.h"
#endif
#include "duktape.h"

// so that name mangling doesn't mess up function names
#ifdef __cplusplus
extern "C"
{
#endif

  static int my_function(lua_State *L)
  {
    const char *str = luaL_checkstring(L, 1);
    duk_context *ctx = duk_create_heap_default();
    duk_equals(ctx, 1, 1);
    printf("Hello from my_function: %s\n", str);
    return 0;
  }
  int luaopen_duktape(lua_State *L)
  {
    static const luaL_Reg duktape[] = {
        {"my_function", my_function},
        {NULL, NULL}};
    luaL_newlib(L, duktape);
    return 1;
  }
#ifdef __cplusplus
}
#endif