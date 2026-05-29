/*
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "mousepad-private.h"
#include "mousepad-settings-store.h"

#ifdef G_OS_WIN32
#include <glib/gwin32.h>
#endif



#ifdef MOUSEPAD_SETTINGS_KEYFILE_BACKEND
/* Needed to use keyfile GSettings backend */
#define G_SETTINGS_ENABLE_BACKEND
#include <gio/gsettingsbackend.h>
#endif



struct _MousepadSettingsStore
{
  GObject parent;

  GSettingsBackend *backend;
  GList *roots;
  GHashTable *keys;
};



typedef struct
{
  const gchar *name;
  GSettings *settings;
} MousepadSettingKey;



static void
mousepad_settings_store_finalize (GObject *object);



G_DEFINE_TYPE (MousepadSettingsStore, mousepad_settings_store, G_TYPE_OBJECT)



static MousepadSettingKey *
mousepad_setting_key_new (const gchar *key_name,
                          GSettings *settings)
{
  MousepadSettingKey *key;

  key = g_slice_new0 (MousepadSettingKey);
  key->name = g_intern_string (key_name);
  key->settings = g_object_ref (settings);

  return key;
}



static void
mousepad_setting_key_free (gpointer data)
{
  MousepadSettingKey *key = data;

  if (G_LIKELY (key != NULL))
    {
      g_object_unref (key->settings);
      g_slice_free (MousepadSettingKey, key);
    }
}



static void
mousepad_settings_store_update_env (void)
{
  const gchar *old_value;
  GPtrArray *paths;
  gchar *new_value = NULL;

#ifndef G_OS_WIN32
  gchar *exe_path;
  gchar *exe_dir;
  gchar *cwd;
  gchar *schema_dir;
#endif

#ifdef G_OS_WIN32
  gchar *install_dir;
  gchar *schema_dir;
#endif

  old_value = g_getenv ("GSETTINGS_SCHEMA_DIR");
  paths = g_ptr_array_new_with_free_func (g_free);

  /* Prefer Mousepad's schema directory so newly added keys are not masked
   * by older schemas that may already exist in user/system paths. */
  g_ptr_array_add (paths, g_strdup (MOUSEPAD_GSETTINGS_SCHEMA_DIR));

  if (old_value != NULL && *old_value != '\0')
    {
      gchar **old_paths;
      gchar **iter;

      old_paths = g_strsplit (old_value, G_SEARCHPATH_SEPARATOR_S, 0);
      for (iter = old_paths; iter != NULL && *iter != NULL; iter++)
        if (**iter != '\0')
          g_ptr_array_add (paths, g_strdup (*iter));

      g_strfreev (old_paths);
    }

#ifndef G_OS_WIN32
  /* Development fallback locations used by local Meson runs on Linux. */
  exe_path = g_file_read_link ("/proc/self/exe", NULL);
  exe_dir = exe_path != NULL ? g_path_get_dirname (exe_path) : NULL;
  g_free (exe_path);

  if (exe_dir != NULL)
    {
      /* Installed layout fallback: <bindir>/../share/glib-2.0/schemas */
      schema_dir = g_build_filename (exe_dir, "..", "share", "glib-2.0", "schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      /* Development layout fallback: <builddir>/runtime-schemas */
      schema_dir = g_build_filename (exe_dir, "..", "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      /* Alternate fallback: <bindir>/runtime-schemas */
      schema_dir = g_build_filename (exe_dir, "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      g_free (exe_dir);
    }

  /* Final fallback from current working directory. */
  cwd = g_get_current_dir ();
  if (cwd != NULL)
    {
      schema_dir = g_build_filename (cwd, "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      schema_dir = g_build_filename (cwd, "build", "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      schema_dir = g_build_filename (cwd, "builddir", "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      g_free (cwd);
    }
#endif

#ifdef G_OS_WIN32
  install_dir = g_win32_get_package_installation_directory_of_module (NULL);
  if (install_dir != NULL)
    {
      /* Installed layout fallback: <bindir>/../share/glib-2.0/schemas */
      schema_dir = g_build_filename (install_dir, "..", "share", "glib-2.0", "schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      /* Development layout fallback: <builddir>/runtime-schemas */
      schema_dir = g_build_filename (install_dir, "..", "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      /* Alternate fallback: <bindir>/runtime-schemas */
      schema_dir = g_build_filename (install_dir, "runtime-schemas", NULL);
      if (g_file_test (schema_dir, G_FILE_TEST_IS_DIR))
        g_ptr_array_add (paths, schema_dir);
      else
        g_free (schema_dir);

      g_free (install_dir);
    }
#endif

  g_ptr_array_add (paths, NULL);
  new_value = g_strjoinv (G_SEARCHPATH_SEPARATOR_S, (gchar **) paths->pdata);
  g_ptr_array_free (paths, TRUE);

  g_setenv ("GSETTINGS_SCHEMA_DIR", new_value, TRUE);
  g_free (new_value);
}



static void
mousepad_settings_store_class_init (MousepadSettingsStoreClass *klass)
{
  GObjectClass *g_object_class;

  g_object_class = G_OBJECT_CLASS (klass);

  g_object_class->finalize = mousepad_settings_store_finalize;

  mousepad_settings_store_update_env ();
}



static void
mousepad_settings_store_finalize (GObject *object)
{
  MousepadSettingsStore *self = MOUSEPAD_SETTINGS_STORE (object);

  g_return_if_fail (MOUSEPAD_IS_SETTINGS_STORE (object));

  if (self->backend != NULL)
    g_object_unref (self->backend);

  g_list_free_full (self->roots, g_object_unref);
  g_hash_table_destroy (self->keys);

  G_OBJECT_CLASS (mousepad_settings_store_parent_class)->finalize (object);
}



static void
mousepad_settings_store_add_key (MousepadSettingsStore *self,
                                 const gchar *setting,
                                 const gchar *key_name,
                                 GSettings *settings)
{
  MousepadSettingKey *key;

  key = mousepad_setting_key_new (key_name, settings);

  g_hash_table_insert (self->keys, (gpointer) g_intern_string (setting), key);
}



static void
mousepad_settings_store_add_settings (MousepadSettingsStore *self,
                                      const gchar *schema_id,
                                      GSettingsSchemaSource *source,
                                      GSettings *settings)
{
  GSettingsSchema *schema;
  GSettings *child_settings;
  gchar **keys, **key, **children, **child;
  gchar *setting, *child_schema_id;
  const gchar *prefix;

  /* loop through keys in schema and store mapping of their setting name to GSettings */
  schema = g_settings_schema_source_lookup (source, schema_id, TRUE);
  if (G_UNLIKELY (schema == NULL))
    {
      g_warning ("Failed to load GSettings schema '%s'", schema_id);
      return;
    }

  keys = g_settings_schema_list_keys (schema);
  prefix = schema_id + MOUSEPAD_ID_LEN + 1;
  for (key = keys; key && *key; key++)
    {
      setting = g_strdup_printf ("%s.%s", prefix, *key);
      mousepad_settings_store_add_key (self, setting, *key, settings);
      g_free (setting);
    }
  g_strfreev (keys);

  /* loop through child schemas and add them too */
  children = g_settings_schema_list_children (schema);
  for (child = children; child && *child; child++)
    {
      child_settings = g_settings_get_child (settings, *child);
      child_schema_id = g_strdup_printf ("%s.%s", schema_id, *child);
      mousepad_settings_store_add_settings (self, child_schema_id, source, child_settings);
      g_object_unref (child_settings);
      g_free (child_schema_id);
    }
  g_strfreev (children);
  g_settings_schema_unref (schema);
}



static void
mousepad_settings_store_init (MousepadSettingsStore *self)
{
#ifdef MOUSEPAD_SETTINGS_KEYFILE_BACKEND
  gchar *conf_file;

  conf_file = g_build_filename (g_get_user_config_dir (), MOUSEPAD_SETTINGS_RELPATH, NULL);
  self->backend = g_keyfile_settings_backend_new (conf_file, "/", NULL);
  g_free (conf_file);
#else
  self->backend = NULL;
#endif

  self->roots = NULL;
  self->keys = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, mousepad_setting_key_free);

  mousepad_settings_store_add_root (self, MOUSEPAD_ID);
}



MousepadSettingsStore *
mousepad_settings_store_new (void)
{
  return g_object_new (MOUSEPAD_TYPE_SETTINGS_STORE, NULL);
}



void
mousepad_settings_store_add_root (MousepadSettingsStore *self,
                                  const gchar *schema_id)
{
  GSettingsSchemaSource *source;
  GSettingsSchema *schema;
  GSettings *root;

  source = g_settings_schema_source_get_default ();
  if (G_UNLIKELY (source == NULL))
    {
      g_warning ("No default GSettings schema source is available");
      return;
    }

  schema = g_settings_schema_source_lookup (source, schema_id, TRUE);

  /* exit silently if no schema is found: plugins may have settings or not */
  if (schema == NULL)
    return;

  root = g_settings_new_full (schema, self->backend, NULL);
  g_settings_schema_unref (schema);

  self->roots = g_list_prepend (self->roots, root);

  mousepad_settings_store_add_settings (self, schema_id, source, root);
}



const gchar *
mousepad_settings_store_lookup_key_name (MousepadSettingsStore *self,
                                         const gchar *setting)
{
  const gchar *key_name = NULL;

  if (!mousepad_settings_store_lookup (self, setting, &key_name, NULL))
    return NULL;

  return key_name;
}



GSettings *
mousepad_settings_store_lookup_settings (MousepadSettingsStore *self,
                                         const gchar *setting)
{
  GSettings *settings = NULL;

  if (!mousepad_settings_store_lookup (self, setting, NULL, &settings))
    return NULL;

  return settings;
}



gboolean
mousepad_settings_store_lookup (MousepadSettingsStore *self,
                                const gchar *setting,
                                const gchar **key_name,
                                GSettings **settings)
{
  MousepadSettingKey *key;

  g_return_val_if_fail (MOUSEPAD_IS_SETTINGS_STORE (self), FALSE);
  g_return_val_if_fail (setting != NULL, FALSE);

  if (key_name == NULL && settings == NULL)
    return g_hash_table_contains (self->keys, setting);

  key = g_hash_table_lookup (self->keys, setting);

  if (G_UNLIKELY (key == NULL))
    return FALSE;

  if (key_name != NULL)
    *key_name = key->name;

  if (settings != NULL)
    *settings = key->settings;

  return TRUE;
}
