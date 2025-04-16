package com.example.tagsnap
import android.os.Message
import android.os.Handler
import android.os.Looper
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.entity.InventoryParameter
import com.rscja.deviceapi.interfaces.IUHFInventoryCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*

// デバッグ用log出力
import android.util.Log

class MainActivity : FlutterActivity() {

    // 通信用の変数
    private var eventSink: EventChannel.EventSink? = null
    private var isInit = false
    private var isReading = false
    private var rfid = RFIDWithUHFUART.getInstance()

    // Dartファイル側との通信を行うための共通文言
    private val channel = "com.example.tagsnap/DevChannel"
    private val stream = "com.example.tagsnap/DevStream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                // 初期化処理
                "initRFID" -> {
                    result.success(initRFID())
                }

                // 読み取り開始（連続読み取り）
                "startRFIDScan" -> {
                    result.success(startRFIDScan())
                }

                // 読み取り停止
                "stopRFIDScan" -> {
                    stopRFIDScanInternal()
                    result.success(true)
                }

                // 終了処理
                "TermRFID" -> {
                    termRFID()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // 読み取り情報をflutter側で受け取るためのチャンネル
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, stream)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // RFIDの初期化処理
    private fun initRFID(): Boolean {
        rfid = RFIDWithUHFUART.getInstance()
        isInit = rfid.init(this)
        return isInit
    }

    // RFIDの連続読み取り開始処理
    private fun startRFIDScan(): Boolean {
        //　初期化終わっていなかったら終了
        if (!isInit) return false

        rfid.setInventoryCallback(object : IUHFInventoryCallback {
            override fun callback(uhftagInfo: UHFTAGInfo) {
                val epc = uhftagInfo.getEPC()
                // flutter側へepc情報を通知
                // flutterの制約によりメインスレッドで必ず返さないといけない
                runOnUiThread {
                    eventSink?.success(epc)
                    // デバッグ用ログ
                    Log.d("Kotlin:MainActivity", "epc情報送信：$epc")
                }
            }
        })

        val param = InventoryParameter()
        param.resultData = InventoryParameter.ResultData().setNeedPhase(false)

        val started = rfid.startInventoryTag(param)

        if (started) {
            isReading = true
            return true
        } else {
            return false
        }
    }

    // RFIDの読み取り停止処理
    private fun stopRFIDScanInternal() {
        if (isReading) {
            rfid.stopInventory()
            isReading = false
        }
    }

    // RFIDの終了処理
    private fun termRFID() {
        if (!isInit) {
            rfid.free()
            isInit = false
        }
    }

    // 破棄時にも念のためRFIDの一通りの終了処理を行う
    override fun onDestroy() {
        stopRFIDScanInternal()
        termRFID()
        super.onDestroy()
    }
}