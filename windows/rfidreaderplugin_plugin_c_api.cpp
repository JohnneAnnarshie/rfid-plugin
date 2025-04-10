#include "include/rfidreaderplugin/rfidreaderplugin_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "rfidreaderplugin_plugin.h"

void RfidreaderpluginPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  rfidreaderplugin::RfidreaderpluginPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
