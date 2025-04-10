//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <rfidreaderplugin/rfidreaderplugin_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) rfidreaderplugin_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RfidreaderpluginPlugin");
  rfidreaderplugin_plugin_register_with_registrar(rfidreaderplugin_registrar);
}
