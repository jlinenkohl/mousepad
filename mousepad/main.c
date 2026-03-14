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
#include "mousepad-application.h"

#ifdef HAVE_LOCALE_H
#include <locale.h>
#endif



gint
main (gint argc,
      gchar **argv)
{
  MousepadApplication *application;
  GApplicationFlags flags;
  const gchar *application_id;
  gint status;

  /* bind the text domain to the locale directory */
  setlocale (LC_ALL, "");
  bindtextdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR);
#ifdef HAVE_BIND_TEXTDOMAIN_CODESET
  bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
#endif

  /* set the package textdomain */
  textdomain (GETTEXT_PACKAGE);

  flags = G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN;
  application_id = MOUSEPAD_ID;

#ifdef G_OS_WIN32
  /*
   * GLib may require a session DBus helper on Windows for unique
   * GApplication registration. Default to non-unique mode unless the
   * environment explicitly requests server mode.
   */
  {
    const gchar *enable_server = g_getenv ("MOUSEPAD_ENABLE_SERVER");

    if (!(enable_server != NULL
          && *enable_server != '\0'
          && g_ascii_strcasecmp (enable_server, "0") != 0
          && g_ascii_strcasecmp (enable_server, "false") != 0))
      {
        g_setenv ("DBUS_SESSION_BUS_ADDRESS", "disabled:", FALSE);
        flags |= G_APPLICATION_NON_UNIQUE;

        /* In non-unique mode, avoid app-id registration paths that can try
         * to spawn missing Win32 DBus helpers and delay startup. */
        application_id = NULL;
      }
  }
#endif

  /* create the application */
  application = g_object_new (MOUSEPAD_TYPE_APPLICATION,
                              "application-id", application_id,
                              "resource-base-path", "/org/xfce/mousepad",
                              "flags", flags,
                              NULL);

  /* run the application */
  status = g_application_run (G_APPLICATION (application), argc, argv);

  /* cleanup */
  g_object_unref (application);

  return status;
}
