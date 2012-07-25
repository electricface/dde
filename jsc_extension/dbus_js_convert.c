#include <dbus/dbus.h>
#include "dbus_js_convert.h"
#include "ddesktop.h"

#define CASE_STRING \
    case DBUS_TYPE_STRING:\
    case DBUS_TYPE_OBJECT_PATH:\
    case DBUS_TYPE_SIGNATURE:\

#define CASE_NUMBER \
    case DBUS_TYPE_BYTE:\
    case DBUS_TYPE_INT16:\
    case DBUS_TYPE_UINT16:\
    case DBUS_TYPE_INT32:\
    case DBUS_TYPE_UINT32:\
    case DBUS_TYPE_INT64:\
    case DBUS_TYPE_UINT64:\
    case DBUS_TYPE_UNIX_FD:\

#define OPEN_CONTAINER(iter, type, sig, sub_iter) do { \
    if (!dbus_message_iter_open_container(iter, type, sig, sub_iter)) { \
            dbus_free(sig);  \
            g_warning("Not have enough memory!"); \
            return FALSE; \
    } \
} while (0)
#define CLOSE_CONTAINER(iter, sub_iter) do { \
    dbus_message_iter_close_container(iter, sub_iter); \
} while (0)

const char* jsvalue_to_signature(JSContextRef ctx, JSValueRef jsvalue) 
{
  char *signature = NULL;
  
  switch (JSValueGetType(ctx, jsvalue))
  {
    case kJSTypeBoolean:
      {
          return DBUS_TYPE_BOOLEAN_AS_STRING;
      }
    case kJSTypeNumber:
      {
          return DBUS_TYPE_DOUBLE_AS_STRING;
      }
    case kJSTypeString:
      {
          return DBUS_TYPE_STRING_AS_STRING;
      }
    case kJSTypeObject:
      {
          return NULL;

        /*if (jsvalue_instanceof(ctx, jsvalue, "Array"))*/
        /*{*/
          /*char *array_signature;*/

          /*propnames = JSObjectCopyPropertyNames(ctx, (JSObjectRef)jsvalue);*/
          /*if (!jsarray_get_signature(ctx, jsvalue, propnames, &array_signature))*/
          /*{ */
            /*g_warning("Could not create array signature");*/
            /*JSPropertyNameArrayRelease(propnames);*/
            /*break;*/
          /*}*/
          /*signature = g_strdup_printf("a%s", array_signature);*/
          /*g_free(array_signature);*/
          /*JSPropertyNameArrayRelease(propnames);*/
          /*break;*/
        /*}*/

        /*[> Default conversion is to dict <]*/
        /*propnames = JSObjectCopyPropertyNames(ctx, (JSObjectRef)jsvalue);*/
        /*jsdict_get_signature(ctx, jsvalue, propnames, &dict_signature);*/
        /*if (dict_signature != NULL)*/
        /*{*/
          /*signature = g_strdup_printf("a%s", dict_signature);*/
          /*g_free(dict_signature);*/
        /*}*/
        /*JSPropertyNameArrayRelease(propnames);*/
        /*break;*/
      }

    case kJSTypeUndefined:
    case kJSTypeNull:
    default:
      g_warning("Signature lookup failed for unsupported type %i", JSValueGetType(ctx, jsvalue));
      break;
  }
  return NULL;
}

gboolean jsvalue_instanceof(JSContextRef ctx, JSValueRef test, const char *klass)
{
  JSStringRef property = JSStringCreateWithUTF8CString(klass);
  JSObjectRef ctor = JSValueToObject(ctx,
                         JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx),
                             property, NULL),
                         NULL);
  JSStringRelease(property);
  return JSValueIsInstanceOfConstructor(ctx, test, ctor, NULL);
}

char* jsstring_to_cstr(JSContextRef ctx, JSStringRef js_string)
{
  size_t len = JSStringGetMaximumUTF8CStringSize(js_string);
  char *c_str = g_new(char, len);
  JSStringGetUTF8CString(js_string, c_str, len);
  return c_str;
}

char* jsvalue_to_cstr(JSContextRef ctx, JSValueRef jsvalue)
{
    if (!JSValueIsString(ctx, jsvalue))
    {
        g_warning("Convert an not JSStringRef to string!");
        return NULL;
    }
    JSStringRef js_string = JSValueToStringCopy(ctx, jsvalue, NULL);
    char* cstr = jsstring_to_cstr(ctx, js_string);
    JSStringRelease(js_string);

    return cstr;
}


gboolean js_to_dbus(JSContextRef ctx, const JSValueRef jsvalue,
    DBusMessageIter *iter, const char* sig, JSValueRef* exception)
{
    DBusSignatureIter s_iter;
    dbus_signature_iter_init(&s_iter, sig);

    int type;
    switch (type = dbus_signature_iter_get_current_type(&s_iter)) {
        case DBUS_TYPE_BOOLEAN:
            {
                dbus_bool_t value = JSValueToBoolean(ctx, jsvalue);
                if (!dbus_message_iter_append_basic(iter, type, &value)) { 
                    g_warning("signatuer:%c error!", type); 
                    return FALSE; 
                }  else {
                    return TRUE;
                }
            }
        case DBUS_TYPE_DOUBLE:
            CASE_NUMBER
            {
                if (!JSValueIsNumber(ctx, jsvalue)) {
                    FILL_EXCEPTION(exception, "jsvalue is not an number!");
                    return FALSE;
                }
                double value = JSValueToNumber(ctx, jsvalue, NULL);
                if (!dbus_message_iter_append_basic(iter, type, &value)) { 
                    g_warning("signatuer:%c error!", type); 
                    return FALSE; 
                } else {
                    return TRUE;
                }
            }
            CASE_STRING
            {
                char* value = jsvalue_to_cstr(ctx, jsvalue);
                if (value == NULL ||
                        !dbus_message_iter_append_basic(iter, type, &value)) {
                    g_free(value);
                    FILL_EXCEPTION(exception, "jsvalue is not an string or memory not enough!");
                    return FALSE; 
                } else {
                    g_free(value);
                    return TRUE;
                }
            }

        case DBUS_TYPE_STRUCT:
            {
                if (!jsvalue_instanceof(ctx, jsvalue, "Array")) {
                    FILL_EXCEPTION(exception, "jsvalue should an array");
                    return FALSE;
                }

                JSPropertyNameArrayRef prop_names = 
                    JSObjectCopyPropertyNames(ctx, (JSObjectRef)jsvalue);
                int p_num = JSPropertyNameArrayGetCount(prop_names);
                if (p_num == 0) {
                    JSPropertyNameArrayRelease(prop_names);
                    FILL_EXCEPTION(exception, "Struct at least have one element!");
                    return FALSE;
                }

                DBusMessageIter sub_iter;
                OPEN_CONTAINER(iter, type, NULL, &sub_iter);

                DBusSignatureIter sub_s_iter;
                dbus_signature_iter_recurse(&s_iter, &sub_s_iter);

                for (int i=0; i<p_num; i++) {
                    JSValueRef value = JSObjectGetProperty(ctx,
                            (JSObjectRef)jsvalue,
                            JSPropertyNameArrayGetNameAtIndex(prop_names, i),
                            NULL);

                    char *sig = dbus_signature_iter_get_signature(&sub_s_iter);
                    if (!js_to_dbus(ctx, value, &sub_iter, sig, exception)) {
                        FILL_EXCEPTION(exception, "Failed append struct with sig:%sTODO");
                        dbus_free(sig);
                        return FALSE;
                    }
                    dbus_free(sig);

                    if (i != p_num-1 && !dbus_signature_iter_next(&sub_s_iter)) {
                        JSPropertyNameArrayRelease(prop_names);
                        CLOSE_CONTAINER(iter, &sub_iter);
                        FILL_EXCEPTION(exception, "to many params filled to struct");
                        return FALSE;
                    }
                }

                if (dbus_signature_iter_next(&sub_s_iter)) {
                    JSPropertyNameArrayRelease(prop_names);
                    CLOSE_CONTAINER(iter, &sub_iter);
                    FILL_EXCEPTION(exception, "need more params by this struct");
                    return FALSE;
                }
                JSPropertyNameArrayRelease(prop_names);
                CLOSE_CONTAINER(iter, &sub_iter);
                return TRUE;
            }
        case DBUS_TYPE_ARRAY:
            if (dbus_signature_iter_get_element_type(&s_iter) ==
                    DBUS_TYPE_DICT_ENTRY) {

                DBusSignatureIter dict_s_iter;
                dbus_signature_iter_recurse(&s_iter, &dict_s_iter);
                char *d_sig = dbus_signature_iter_get_signature(&dict_s_iter);

                DBusMessageIter sub_iter;
                OPEN_CONTAINER(iter, type, d_sig, &sub_iter);
                dbus_free(d_sig);

                JSPropertyNameArrayRef prop_names = JSObjectCopyPropertyNames(ctx,
                        (JSObjectRef)jsvalue);
                int p_num = JSPropertyNameArrayGetCount(prop_names);

                DBusSignatureIter dict_sub_s_iter;
                dbus_signature_iter_recurse(&dict_s_iter, &dict_sub_s_iter);

                int key_type = dbus_signature_iter_get_current_type(&dict_sub_s_iter);
                dbus_signature_iter_next(&dict_sub_s_iter);
                char *val_sig = dbus_signature_iter_get_signature(&dict_sub_s_iter);


                for (int i=0; i<p_num; i++) {
                    DBusMessageIter dict_iter;
                    OPEN_CONTAINER(&sub_iter, DBUS_TYPE_DICT_ENTRY,
                            NULL, &dict_iter);

                    JSStringRef key_str = JSPropertyNameArrayGetNameAtIndex(prop_names, i);

                    //TODO: fetch key type
                    switch (key_type) {
                        CASE_STRING
                        {
                            char *value = jsstring_to_cstr(ctx, key_str);
                            dbus_message_iter_append_basic(&dict_iter, key_type, &value);
                            g_free(value);
                            break;
                        }
                        case DBUS_TYPE_DOUBLE:
                        CASE_NUMBER
                        {
                            //TODO detect illegal number format
                            JSValueRef excp = NULL;
                            double value = JSValueToNumber(ctx, 
                                    JSValueMakeString(ctx, key_str), &excp);

                            if (excp != NULL) {
                                FILL_EXCEPTION(exception, "dict_entry's key must be an number to match the signature!");
                                return FALSE;
                            }

                            dbus_message_iter_append_basic(&dict_iter, key_type, &value);
                            break;
                        }
                        default:
                        {
                            FILL_EXCEPTION(exception, "DICT_ENTRY's key must basic type, and you should not see this warning in javascript runtime");
                            dbus_free(val_sig);
                            JSPropertyNameArrayRelease(prop_names);
                            CLOSE_CONTAINER(iter, &sub_iter);
                            return FALSE;
                        }
                    }



                    js_to_dbus(ctx,
                            JSObjectGetProperty(ctx, (JSObjectRef)jsvalue,
                                key_str, NULL),
                            &dict_iter, val_sig,
                            exception);

                    CLOSE_CONTAINER(&sub_iter, &dict_iter);
                }
                dbus_free(val_sig);
                JSPropertyNameArrayRelease(prop_names);

                CLOSE_CONTAINER(iter, &sub_iter);
                return TRUE;
            } else {
                DBusMessageIter sub_iter;
                DBusSignatureIter array_s_iter;
                char *array_signature = NULL;
                if (!jsvalue_instanceof(ctx, jsvalue, "Array")) {
                    FILL_EXCEPTION(exception, "jsvalue is not an array type");
                    return FALSE;
                }
                dbus_signature_iter_recurse(&s_iter, &array_s_iter);
                array_signature =
                    dbus_signature_iter_get_signature(&array_s_iter);

                JSPropertyNameArrayRef prop_names =
                    JSObjectCopyPropertyNames(ctx, (JSObjectRef)jsvalue);
                OPEN_CONTAINER(iter, type, array_signature, &sub_iter);

                int p_num = JSPropertyNameArrayGetCount(prop_names);

                for (int i=0; i<p_num; i++) {
                    JSValueRef value = JSObjectGetPropertyAtIndex(ctx,
                            (JSObjectRef)jsvalue, i, NULL);
                    js_to_dbus(ctx, value,
                            &sub_iter, array_signature,
                            exception);
                }

                g_free(array_signature);
                JSPropertyNameArrayRelease(prop_names);

                CLOSE_CONTAINER(iter, &sub_iter);
                return TRUE;
            }

        case DBUS_TYPE_VARIANT:
            {
                //TODO: detect the signature of the jsvalue
                DBusMessageIter sub_iter;
                DBusSignatureIter v_iter;
                char *v_sig;
                dbus_signature_iter_recurse(&s_iter, &v_iter);
                v_sig = jsvalue_to_signature(ctx, jsvalue);

                if (v_sig == NULL) {
                    FILL_EXCEPTION(exception, "Can't detect the variant type");
                    return FALSE;
                }

                OPEN_CONTAINER(iter, DBUS_TYPE_VARIANT, v_sig, &sub_iter);

                if (!js_to_dbus(ctx, jsvalue, &sub_iter, v_sig, exception)) {
                    FILL_EXCEPTION(exception, "Failed to append variant contents with signature");
                    return FALSE;
                }

                CLOSE_CONTAINER(iter, &sub_iter);
                return TRUE;

            }

        case DBUS_TYPE_DICT_ENTRY:
            g_assert_not_reached();
            break;
        default:
            g_warning("Unknow signature type :%c", type);
                return FALSE;
    }
}



JSValueRef dbus_to_js(JSContextRef ctx, DBusMessageIter *iter)
{
    JSValueRef jsvalue = NULL;
    int type = dbus_message_iter_get_arg_type(iter);
    switch (type) {
        CASE_STRING
            {
                const char *value = NULL;
                dbus_message_iter_get_basic(iter, &value);

                JSStringRef js_string = JSStringCreateWithUTF8CString(value);
                jsvalue = JSValueMakeString(ctx, js_string);
                JSStringRelease(js_string);
                break;
            }
        CASE_NUMBER
            {
                dbus_uint64_t value = 0;
                dbus_message_iter_get_basic(iter, &value);
                jsvalue = JSValueMakeNumber(ctx, value);
                break;
            }
        case DBUS_TYPE_DOUBLE:
            {
                double value = 0;
                dbus_message_iter_get_basic(iter, &value);
                jsvalue = JSValueMakeNumber(ctx, value);
                break;
            }
        case DBUS_TYPE_BOOLEAN:
            {
                gboolean value = NULL;
                dbus_message_iter_get_basic(iter, &value);
                jsvalue = JSValueMakeBoolean(ctx, value);
                break;
            }
        case DBUS_TYPE_VARIANT:
            {
                DBusMessageIter c_iter;
                dbus_message_iter_recurse(iter, &c_iter);
                jsvalue = dbus_to_js(ctx, &c_iter);
                break;
            }
        case DBUS_TYPE_DICT_ENTRY:
            g_assert_not_reached();
            break;

        case DBUS_TYPE_STRUCT:
        case DBUS_TYPE_ARRAY:
            {

                DBusMessageIter c_iter;
                dbus_message_iter_recurse(iter, &c_iter);

                if (dbus_message_iter_get_arg_type(&c_iter) == DBUS_TYPE_DICT_ENTRY) {
                    jsvalue = JSObjectMake(ctx, NULL, NULL);
                } else {
                    jsvalue = JSObjectMakeArray(ctx, 0, NULL, NULL);
                }

                int i=0;
                do {
                    if (dbus_message_iter_get_arg_type(&c_iter) == 
                            DBUS_TYPE_DICT_ENTRY) {
                        JSValueRef key;
                        JSStringRef key_str;
                        JSValueRef value;

                        DBusMessageIter d_iter;
                        dbus_message_iter_recurse(&c_iter, &d_iter);

                        key = dbus_to_js(ctx, &d_iter);
                        key_str = JSValueToStringCopy(ctx, key, NULL);

                        dbus_message_iter_next(&d_iter);
                        value = dbus_to_js(ctx, &d_iter);

                        JSObjectSetProperty(ctx, (JSObjectRef)jsvalue,
                                key_str, value, 0, NULL);

                        JSStringRelease(key_str);
                    } else {
                        JSObjectSetPropertyAtIndex(ctx, (JSObjectRef)jsvalue,
                                i++, dbus_to_js(ctx, &c_iter), NULL);
                    }
                } while(dbus_message_iter_next(&c_iter));
                break;
            }

        case DBUS_TYPE_INVALID:
            jsvalue = JSValueMakeUndefined(ctx);
            break;
        default:
            g_warning("didn't support signature type:%c", type);
            jsvalue = JSValueMakeUndefined(ctx);
            break;
    }
    return jsvalue;
}