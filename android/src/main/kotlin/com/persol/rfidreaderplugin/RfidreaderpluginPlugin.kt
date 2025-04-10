package com.persol.rfidreaderplugin

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.uk.tsl.rfid.DeviceListActivity
import com.uk.tsl.rfid.DeviceListActivity.SELECT_DEVICE_REQUEST
import com.uk.tsl.rfid.asciiprotocol.AsciiCommander
import com.uk.tsl.rfid.asciiprotocol.commands.AbortCommand
import com.uk.tsl.rfid.asciiprotocol.commands.BatteryStatusCommand
import com.uk.tsl.rfid.asciiprotocol.commands.InventoryCommand
import com.uk.tsl.rfid.asciiprotocol.device.ConnectionState
import com.uk.tsl.rfid.asciiprotocol.device.IAsciiTransport
import com.uk.tsl.rfid.asciiprotocol.device.Reader
import com.uk.tsl.rfid.asciiprotocol.device.ReaderManager
import com.uk.tsl.rfid.asciiprotocol.device.TransportType
import com.uk.tsl.rfid.asciiprotocol.enumerations.TriState
import com.uk.tsl.rfid.asciiprotocol.responders.LoggerResponder
import com.uk.tsl.rfid.asciiprotocol.responders.TransponderData
import com.uk.tsl.utils.Observable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlin.math.round

const val TAG = "RFIDREADERPLUGIN"

/** RfidreaderpluginPlugin */
class RfidreaderpluginPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var connectionEventChannel: EventChannel

  private lateinit var context: Context
  private var activity: Activity? = null


  private var currentReader: Reader? = null
  private var mIsSelectingReader = false
  private lateinit var inventoryResponder: InventoryCommand


  companion object {
    lateinit var inventoryCommand: InventoryCommand
    var deviceInfo: Map<*,*>? = null
    var isScanning = false
    //var transponderEpcList: MutableList<Map<String, Any>?>? = mutableListOf()
    var deviceBatteryLevel: Int? = null
    var eventSink: EventChannel.EventSink? = null
    var connectionEventSink: EventChannel.EventSink? = null
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Log.d(TAG, "onAttachedToEngine Called")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rfidreadermethodchannel")
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.applicationContext
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "rfidreadereventchannel")
    eventChannel.setStreamHandler(
      object : EventChannel.StreamHandler{
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          scanStart()
          eventSink = events
        }

        override fun onCancel(arguments: Any?) {
          scanStop()
          eventSink = null
        }
      }
    )

    connectionEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "rfidreaderconnectioneventchannel")
    connectionEventChannel.setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          connectionEventSink = events
        }

        override fun onCancel(arguments: Any?) {
          connectionEventSink = null
        }

      }
    )

    (context as Application).registerActivityLifecycleCallbacks(lifecycleCallback)

    AsciiCommander.createSharedInstance(context)
    val commander: AsciiCommander = getCommander()

    commander.clearResponders()
    commander.addResponder(LoggerResponder())
    commander.addResponder(IAsciiCommandResponder())
    commander.addSynchronousResponder()

    ReaderManager.create(context)
    // Add observers for changes
    ReaderManager.sharedInstance().readerList.readerAddedEvent().addObserver(mAddedObserver)
    ReaderManager.sharedInstance().readerList.readerUpdatedEvent().addObserver(mUpdatedObserver)
    ReaderManager.sharedInstance().readerList.readerRemovedEvent().addObserver(mRemovedObserver)

    // This is the command that will be used to perform configuration changes and inventories
    inventoryCommand = InventoryCommand()
    inventoryCommand.resetParameters = TriState.YES
    // Configure the type of inventory
    inventoryCommand.includeTransponderRssi = TriState.YES
    inventoryCommand.includeChecksum = TriState.YES
    inventoryCommand.includePC = TriState.YES
    inventoryCommand.includeDateTime = TriState.YES

    // Handle the alerts in the App
    inventoryCommand.useAlert = TriState.NO

    //Use and InventoryCommand as a responder to capture all incoming inventory responses
    inventoryResponder = InventoryCommand()

    // Also capture the responses that were not from App commands
    inventoryResponder.setCaptureNonLibraryResponses(true)

    // Notify when each transponder is seen
    inventoryResponder.transponderReceivedDelegate = ITransponderReceivedDelegate()

    inventoryResponder.responseLifecycleDelegate = ICommandResponseLifecycleDelegate()

    commander.addResponder(inventoryResponder)

  }


  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }
    else if (call.method == "getBatteryPercentage") {
     val bCommand =  BatteryStatusCommand.synchronousCommand()
      getCommander().executeCommand(bCommand)
      result.success(bCommand.batteryLevel)
    }
    else if (call.method == "getPowerBarLimits") {
      getPowerLimits(result)
    }
    else if (call.method == "getOutputPowerLevel") {
      result.success(inventoryCommand.outputPower)
    }
    else if (call.method == "setOutputPowerLevel") {
      result.success(setOutputPower(call.arguments as Double))
    }
    else if (call.method == "connectReader") {
      val selectIntent = Intent(context, DeviceListActivity::class.java)
      activity?.startActivityForResult(
        selectIntent,
        SELECT_DEVICE_REQUEST
      )
      result.success(true)
    }
    else if (call.method == "disconnectReader") {
      if (currentReader != null) {
        currentReader?.disconnect()
      }
      result.success(true)
    }
    else if (call.method == "scanStop") {
      scanStop()
      result.success(true)
    }
    else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
 }

  private fun autoSelectReader(attemptReconnect: Boolean) {
    val readerList = ReaderManager.sharedInstance().readerList
    var usbReader: Reader? = null
    if (readerList.list().size >= 1) {
      // Currently only support a single USB connected device so we can safely take the
      // first CONNECTED reader if there is one
      for (reader in readerList.list()) {
        if (reader.hasTransportOfType(TransportType.USB)) {
          usbReader = reader
          break
        }
      }
    }

    if (currentReader == null) {
      if (usbReader != null) {
        // Use the Reader found, if any
        currentReader = usbReader
        getCommander().reader = currentReader
      }
    } else {
      // If already connected to a Reader by anything other than USB then
      // switch to the USB Reader
      val activeTransport: IAsciiTransport? = currentReader!!.activeTransport
      if (activeTransport?.type() != TransportType.USB && usbReader != null) {
          Toast.makeText(
            context,
            "Disconnecting from: ${ currentReader!!.displayName}",
            Toast.LENGTH_SHORT

          ).show()
        currentReader!!.disconnect()

        currentReader = usbReader

        // Use the Reader found, if any
        getCommander().reader = currentReader
      }
    }

    // Reconnect to the chosen Reader
    if (currentReader != null && !currentReader?.isConnecting!!
      && (currentReader?.activeTransport == null || currentReader?.activeTransport!!
        .connectionStatus().value() == ConnectionState.DISCONNECTED)
    ) {
      // Attempt to reconnect on the last used transport unless the ReaderManager is cause of OnPause (USB device connecting)
      if (attemptReconnect) {
        if (currentReader!!.allowMultipleTransports() || currentReader?.lastTransportType == null) {
          // Reader allows multiple transports or has not yet been connected so connect to it over any available transport
          if (currentReader!!.connect()) {
              Toast.makeText(
                context,
                "Connecting to: ${ currentReader!!.displayName}",
                Toast.LENGTH_SHORT
              ).show()
          }
        } else {
          // Reader supports only a single active transport so connect to it over the transport that was last in use
          if (currentReader!!.connect(currentReader?.lastTransportType)) {
              Toast.makeText(
                context,
                "Connecting (over last transport) to: ${ currentReader!!.displayName}",
                Toast.LENGTH_SHORT
              ).show()
          }
        }
      }
    }
  }


  private var mAddedObserver: Observable.Observer<Reader?> =
    Observable.Observer<Reader?> { observable, reader -> // See if this newly added Reader should be used
      autoSelectReader(true)
    }

  private var mUpdatedObserver: Observable.Observer<Reader> =
    Observable.Observer { observable, reader -> }

  private var mRemovedObserver: Observable.Observer<Reader> =
    Observable.Observer<Reader> { observable, reader ->
      // Was the current Reader removed
      if (reader === currentReader) {
        currentReader = null

        // Stop using the old Reader
        getCommander().reader = currentReader
      }
    }

  private val mMessageReceiver: BroadcastReceiver = object : BroadcastReceiver() {
    @SuppressLint("SuspiciousIndentation")
    override fun onReceive(context: Context, intent: Intent) {
      val connectionStateMsg = getCommander().connectionState.toString()
      Log.d(
        "",
        "AsciiCommander state changed - isConnected: " + getCommander().isConnected + " (" + connectionStateMsg + ")"
      )

      if (getCommander().isConnected) {
        // Report the battery level when Reader connects
        val bCommand = BatteryStatusCommand.synchronousCommand()
        getCommander().executeCommand(bCommand)
        val batteryLevel = bCommand.batteryLevel
        deviceBatteryLevel = batteryLevel
        activity?.runOnUiThread {
          Toast.makeText(
            context,
            "Connected: ${currentReader?.displayName} ($batteryLevel%)",
            Toast.LENGTH_SHORT
          ).show()
        }
      } else if (getCommander().connectionState == ConnectionState.DISCONNECTED) {
        // A manual disconnect will have cleared mReader
        if (currentReader != null) {
          activity?.runOnUiThread {
            Toast.makeText(
              context,
              "Reader: ${currentReader?.displayName} disconnected",
              Toast.LENGTH_SHORT
            ).show()
          }
          // See if this is from a failed connection attempt
          if (!currentReader?.wasLastConnectSuccessful()!!) {
            activity?.runOnUiThread {
              Toast.makeText(
                context,
                "Failed to connect!",
                Toast.LENGTH_SHORT
              ).show()
            }
            // Unable to connect so have to choose reader again
            currentReader = null
          }
        }
      }
    }
  }
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener { requestCode, resultCode, data ->
      if (requestCode == SELECT_DEVICE_REQUEST) {
        handleDeviceSelection(resultCode, data)
        true
      } else {
        false
      }
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  private fun handleDeviceSelection(resultCode: Int, data: Intent?) {
    if (resultCode == Activity.RESULT_OK) {
      val readerIndex = data?.extras?.getInt(DeviceListActivity.EXTRA_DEVICE_INDEX) ?: return
      val action = data.extras?.getInt(DeviceListActivity.EXTRA_DEVICE_ACTION) ?: return
      val chosenReader: Reader = ReaderManager.sharedInstance().readerList.list()[readerIndex]
      currentReader = chosenReader

      Log.d(TAG, "SELECTED READER: ${currentReader?.displayName}")

      if (action == DeviceListActivity.DEVICE_CHANGE || action == DeviceListActivity.DEVICE_DISCONNECT) {
        connectionEventSink?.success(false)
        activity?.runOnUiThread {
          Toast.makeText(
            activity,
            "Disconnecting from: ${currentReader?.displayName}",
            Toast.LENGTH_SHORT
          ).show()
        }
        currentReader?.disconnect()
        if (action == DeviceListActivity.DEVICE_DISCONNECT) {
          currentReader = null
        }
      }

      if (action == DeviceListActivity.DEVICE_CHANGE || action == DeviceListActivity.DEVICE_CONNECT) {
        activity?.runOnUiThread {
          Toast.makeText(
            activity,
            "Selected: ${currentReader?.displayName}",
            Toast.LENGTH_SHORT
          ).show()
        }
        getCommander().reader = currentReader
        if (currentReader != null) {
          connectionEventSink?.success(true)
        }

        // Send selected reader info back to Flutter
        val readerInfo = mapOf(
          "name" to currentReader?.displayName,
          "index" to readerIndex,
          "action" to action
        )
        deviceInfo = readerInfo
        eventSink?.success(readerInfo)
      }
    } else if (resultCode == Activity.RESULT_CANCELED) {
      Log.d(TAG, "DeviceListActivity canceled")
      eventSink?.success(mapOf("canceled" to true))
    }
  }


  private val lifecycleCallback = object : Application.ActivityLifecycleCallbacks {
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityStarted(activity: Activity) {}

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onActivityResumed(resumedActivity: Activity) {
      Log.d(TAG, "onActivityResumed: EXECUTED")
      resumedActivity.let {
        ContextCompat.registerReceiver(
          it,
          mMessageReceiver,
          IntentFilter(AsciiCommander.STATE_CHANGED_NOTIFICATION),
          ContextCompat.RECEIVER_NOT_EXPORTED
        )
        Log.d(TAG, "onActivityResumed: REGISTERED ${mMessageReceiver.resultCode}")
      }
        val readerManagerDidCauseOnPause = ReaderManager.sharedInstance().didCauseOnPause()
        ReaderManager.sharedInstance().onResume()
        ReaderManager.sharedInstance().updateList()
        autoSelectReader(!readerManagerDidCauseOnPause)
          mIsSelectingReader = false
    }

    override fun onActivityPaused(activity: Activity) {
      activity.let{ act ->
        act.unregisterReceiver(mMessageReceiver)
        // Disconnect from the reader to allow other Apps to use it
        // unless pausing when USB device attached or using the DeviceListActivity to select a Reader
        if (!mIsSelectingReader && !ReaderManager.sharedInstance()
            .didCauseOnPause() && currentReader != null
        ) {
          currentReader?.disconnect()
        }
        ReaderManager.sharedInstance().onPause()
      }
    }

    override fun onActivityStopped(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {
      ReaderManager.sharedInstance().readerList.readerAddedEvent().removeObserver(mAddedObserver)
      ReaderManager.sharedInstance().readerList.readerUpdatedEvent().removeObserver(mUpdatedObserver)
      ReaderManager.sharedInstance().readerList.readerRemovedEvent().removeObserver(mRemovedObserver)

    }

  }

}




class IAsciiCommandResponder : com.uk.tsl.rfid.asciiprotocol.responders.IAsciiCommandResponder {
  override fun isResponseFinished(): Boolean {
    return false
  }

  override fun clearLastResponse() {
  }

  override fun processReceivedLine(p0: String?, p1: Boolean): Boolean {
    if (p0?.startsWith("EP: ") == true) {
      Log.d("PROCESS LOG", p0.split("EP: ").last())
    }
    return false
  }

}

class ITransponderReceivedDelegate :
  com.uk.tsl.rfid.asciiprotocol.responders.ITransponderReceivedDelegate {
  override fun transponderReceived(transponder: TransponderData?, p1: Boolean) {
    if (transponder?.epc != null){
      Log.d(TAG, "EPC: ${transponder.epc}" )
      MainScope().launch {
        RfidreaderpluginPlugin.eventSink?.success(
          mapOf(
            "epc" to transponder.epc,
            "rssi" to transponder.rssi,
            "pc" to transponder.pc
          )
        )
      }

//      Log.d(TAG, "EPC LIST: ${RfidreaderpluginPlugin.transponderEpcList}" )
    }
  }

}

class ICommandResponseLifecycleDelegate :
  com.uk.tsl.rfid.asciiprotocol.responders.ICommandResponseLifecycleDelegate {
  override fun responseBegan() {
  }

  override fun responseEnded() {
    Log.d(TAG, "RESPONSE ENDED")

    if (RfidreaderpluginPlugin.isScanning) {
      getCommander().executeCommand(RfidreaderpluginPlugin.inventoryCommand)
    }
  }

}

private fun getCommander(): AsciiCommander {
  return AsciiCommander.sharedInstance()
}

// Start the continuous inventory scan with the current command parameters
//
fun scanStart() {
  testForAntenna()
  if (getCommander().isConnected) {
    RfidreaderpluginPlugin.inventoryCommand.takeNoAction = TriState.NO
    RfidreaderpluginPlugin.isScanning = true
    getCommander().executeCommand(RfidreaderpluginPlugin.inventoryCommand)
  }
}


//
// Stop the continuous inventory scan
//
fun scanStop() {
  RfidreaderpluginPlugin.inventoryCommand.takeNoAction = TriState.YES

  if (getCommander().isConnected) {
    // Cancel any running inventory
    RfidreaderpluginPlugin.isScanning = false
    getCommander().executeCommand(AbortCommand())
  }
}

fun testForAntenna() {
  if (getCommander().isConnected) {
    val testCommand = InventoryCommand.synchronousCommand()
    testCommand.takeNoAction = TriState.YES
    getCommander().executeCommand(testCommand)
    if (!testCommand.isSuccessful) {
      Log.d(TAG, "No Antenna")
    }
  }
}

//----------------------------------------------------------------------------------------------
// Power seek bar
//----------------------------------------------------------------------------------------------
private fun getPowerBarLimits(): Map<String, Int> {
  val deviceProperties = getCommander().deviceProperties
//    mPowerSeekBar.setMax(deviceProperties.maximumCarrierPower - deviceProperties.minimumCarrierPower)
//    mPowerLevel = deviceProperties.maximumCarrierPower
//    mPowerSeekBar.setProgress(mPowerLevel - deviceProperties.minimumCarrierPower)
  return mapOf(
    "min" to deviceProperties.minimumCarrierPower,
    "max" to deviceProperties.maximumCarrierPower
  )
}

private fun getPowerLimits(result: Result) {
  val deviceProperties = getCommander().deviceProperties
  result.success(mapOf(
    "min" to deviceProperties.minimumCarrierPower,
    "max" to deviceProperties.maximumCarrierPower
  ))
}

private fun setOutputPower(powerLevel: Double) : Double {
  //Note: powerLevel is in range [0f, 1.0f]
  //Note powerLimit is a map of "min" and "max" power values
  val powerLimits : Map<String, Int> = getPowerBarLimits()
  val minPower = powerLimits["min"] ?: throw IllegalArgumentException("Min power value not found")
  val maxPower = powerLimits["max"] ?: throw IllegalArgumentException("Max power value not found")

  val outputPower = minPower + (powerLevel * (maxPower - minPower))
  RfidreaderpluginPlugin.inventoryCommand.outputPower = round(outputPower).toInt()

  return outputPower
}
