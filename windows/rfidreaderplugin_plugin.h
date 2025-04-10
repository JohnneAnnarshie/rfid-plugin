#ifndef FLUTTER_PLUGIN_RFIDREADERPLUGIN_PLUGIN_H_
#define FLUTTER_PLUGIN_RFIDREADERPLUGIN_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace rfidreaderplugin {

class RfidreaderpluginPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RfidreaderpluginPlugin();

  virtual ~RfidreaderpluginPlugin();

  // Disallow copy and assign.
  RfidreaderpluginPlugin(const RfidreaderpluginPlugin&) = delete;
  RfidreaderpluginPlugin& operator=(const RfidreaderpluginPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace rfidreaderplugin

#endif  // FLUTTER_PLUGIN_RFIDREADERPLUGIN_PLUGIN_H_
