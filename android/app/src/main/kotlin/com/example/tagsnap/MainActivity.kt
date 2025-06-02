package com.example.tagsnap

// デバッグ用log出力
import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.rscja.barcode.BarcodeDecoder
import com.rscja.barcode.BarcodeFactory
import com.rscja.deviceapi.entity.BarcodeEntity
import com.rscja.deviceapi.RFIDWithUHFUART
import com.rscja.deviceapi.entity.InventoryParameter
import com.rscja.deviceapi.entity.UHFTAGInfo
import com.rscja.deviceapi.interfaces.IUHFInventoryCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.*

//NFC対応
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall



class MainActivity : FlutterActivity() {

    // 通信用の変数
    private var eventSink: EventChannel.EventSink? = null
    private var isInit = false
    private var isReading = false
    private var rfid: RFIDWithUHFUART? = null
    private var isInitQR = false
    private var barcodeDecoder: BarcodeDecoder? = null

    // 連続送信時のディレイ処理用
    private var isSending = false
    private var delaySendRFIFInfoTime = 1L
    private var latestTag: String? = null
    private var latestTagInfo: Map<String, Any> = emptyMap()

    // QR用
    private var latestQRInfo: Map<String, Any> = emptyMap()

    // Dartファイル側との通信を行うための共通文言
    private val channel = "com.example.tagsnap/DevChannel"
    private val stream = "com.example.tagsnap/DevStream"

    // ビープ音用変数
    private lateinit var toneGenerator: ToneGenerator
    private lateinit var audioManager: AudioManager

    //NFC判定（光嶋追加）
    private val CHANNEL = "com.example.nfc/settings"


    // 作業メモ
    // 機能ごとにファイルを分けたい

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                // RFID系
                // RFID初期化処理
                "initRFID" -> {
                    result.success(initRFID())
                }
                // RFID読み取り開始（連続読み取り）
                "startRFIDScan" -> {
                    result.success(startRFIDScan())
                }
                // RFID読み取り停止
                "stopRFIDScan" -> {
                    stopRFIDScanInternal()
                    result.success(true)
                }
                // RFID読み取り開始（単一読み取り）
                "startRFIDScanOnce" -> {
                    result.success(startRFIDScanOnce())
                }
                // RFID終了処理
                "TermRFID" -> {
                    termRFID()
                    result.success(true)
                }

                // QR系
                // QR初期化処理
                "initQR" -> {
                    result.success(initQR())
                }
                // QR読み取り開始
                "startQRScan" -> {
                    result.success(startScanQRCode())
                }
                // QR読み取り停止
                "stopQRScan" -> {
                    result.success(stopScanQRCode())
                }
                // QR終了処理
                "TermQR" -> {
                    termQR()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // NFC設定画面を開くチャンネルの追加
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler{call: MethodCall, result: MethodChannel.Result ->
            if (call.method == "openNfcSettings") {
                val intent = Intent(Settings.ACTION_NFC_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                result.success(null)
            } else {
                result.notImplemented()
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
        // 初期化済み状態で終了なしに再度呼ばれている時は再初期化しないようにする
        if(!isInit) {
            rfid = RFIDWithUHFUART.getInstance()
            isInit = rfid?.init(this) ?: false
        }
        return isInit
    }

    // RFIDの連続読み取り開始処理
    private fun startRFIDScan(): Boolean {
        //　初期化終わっていなかったら終了
        if (!isInit) return false

        rfid?.setInventoryCallback(object : IUHFInventoryCallback {
            override fun callback(uhfTagInfo: UHFTAGInfo) {
                val epc = uhfTagInfo.getEPC()
                // 最新受信情報を格納
                latestTag = epc
                // 受信した情報をMapとして変換
                convertReceiveTagInfo(uhfTagInfo)

                // 送信処理が動いていない場合は呼び出し
                if (!isSending) {
                    isSending = true
                    sendNextTagInfo()
                }
            }
        })

        val param = InventoryParameter()
        param.resultData = InventoryParameter.ResultData().setNeedPhase(false)

        val started = rfid?.startInventoryTag(param) ?: false

        if (started) {
            isReading = true
            return true
        } else {
            return false
        }
    }

    // 連続送信時の数秒待機用
    private fun sendNextTagInfo() {
        Handler(Looper.getMainLooper()).postDelayed({
            // Flutter側へ送信
            sendToFlutter()

            // 送信後の情報はクリア
            latestTag = null
            latestTagInfo = emptyMap()

            // もしここに至るまで受信が行われていたら再呼び出し、なかったら次の呼び出しまで停止
            if (latestTagInfo.isNotEmpty()) {
                sendNextTagInfo()
            } else {
                isSending = false
            }
        }, delaySendRFIFInfoTime)
    }

    // RFIDの読み取り停止処理
    private fun stopRFIDScanInternal() {
        if (isReading) {
            rfid?.stopInventory()
            isReading = false
        }
    }

    // RFIDの単一読み取り処理
    private fun startRFIDScanOnce() {
        //　初期化終わっていなかったら終了
        if (!isInit) return

        // null非許容にするため一応rfidをチェック
        rfid?.let {
            // 単一読み取りを行う
            val uhfTagInfo = it.inventorySingleTag()
            // 受信した情報をMapとして変換
            convertReceiveTagInfo(uhfTagInfo)
            // Flutter側へ送信
            sendToFlutter()
        }
    }



    // RFID結果情報を格納用MAPに変換
    private fun convertReceiveTagInfo(rcvTagInfo: UHFTAGInfo) {

        latestTag = rcvTagInfo.getEPC()

        // 情報として得られるものが不明確なため保留
        // uhfTagInfo.getExtraData(String) // 引数がkey情報
        // 戻り値がAPI内のクラスになるため無視
        // uhfTagInfo.getChipInfo() // 戻り値はUHFTAGInfo.ChipInfo

        // 格納前に成形が必要な情報を受ける(nullだったら空の配列にする)
        val EpcBytes: ByteArray = rcvTagInfo.getEpcBytes() ?: ByteArray(0)
        val tidBytes: ByteArray = rcvTagInfo.getTidBytes() ?: ByteArray(0)
        val userBytes: ByteArray = rcvTagInfo.getUserBytes() ?: ByteArray(0)

        // 格納情報をmapに入れる
        latestTagInfo = mapOf(
            "type" to "rfid",
            "epc" to rcvTagInfo.getEPC(),
            "ant" to rcvTagInfo.getAnt(),
            "count" to rcvTagInfo.getCount(),
            "epcBytes" to EpcBytes.toList(),
            "freqPoint" to rcvTagInfo.getFrequencyPoint(),
            "index" to rcvTagInfo.getIndex(),
            "pc" to rcvTagInfo.getPc(),
            "phase" to rcvTagInfo.getPhase(),
            "remain" to rcvTagInfo.getRemain(),
            "reserved" to rcvTagInfo.getReserved(),
            "rssi" to rcvTagInfo.getRssi(),
            "tid" to rcvTagInfo.getTid(),
            "tidBytes" to tidBytes.toList(),
            "timeStamp" to rcvTagInfo.getTimestamp(),
            "user" to rcvTagInfo.getUser(),
            "userBytes" to userBytes.toList()
        )
    }

    private fun sendToFlutter() {
        // 最後に受信したタグ情報をチェック
        if(latestTagInfo.isNotEmpty()) {
            // 現在音量を取得
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
            // ミュートされていなかったらビープ音を鳴らす
            //if (currentVolume > 0) {
            //    toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
            //}
            // flutterの制約によりメインスレッドで必ず返さないといけない
            runOnUiThread {
                // flutterへの情報送信
                eventSink?.success(latestTagInfo)
                // デバッグ用ログ
                Log.d("Kotlin:MainActivity", "epc情報送信：$latestTag")
            }
        }
    }

    // RFIDの終了処理
    private fun termRFID() {
        if (!isInit) {
            rfid?.setInventoryCallback(null)
            rfid?.free()
            isInit = false
        }
    }


    // QRの初期化処理
    private fun initQR(): Boolean {
        // 初期化処理通過済みで未closeだったら行わない
        if(!isInitQR) {
            barcodeDecoder = BarcodeFactory.getInstance().getBarcodeDecoder()
            barcodeDecoder?.open(this)
            isInitQR = true

            // 結果情報受信時はここでflutter側への応答を返す
            barcodeDecoder?.setDecodeCallback(object : BarcodeDecoder.DecodeCallback {
                override fun onDecodeComplete(barcodeEntity: BarcodeEntity){
                    // 成功時
                    if (barcodeEntity.getResultCode() === BarcodeDecoder.DECODE_SUCCESS) {
                        // 結果情報を格納
                        convertReceiveQR(barcodeEntity)
                        // flutterの制約によりメインスレッドで必ず返さないといけない
                        runOnUiThread {
                            // デバッグ用
                            // 情報の取得
                            var tmpinfo = barcodeDecoder?.getDecoderSVersionInfo()
                            Log.d("Kotlin:MainActivity", "取得情報：$tmpinfo")

                            // flutterへの情報送信
                            eventSink?.success(latestQRInfo)
                            // デバッグ用ログ
                            Log.d("Kotlin:MainActivity", "QR情報送信")

                        }
                        // 結果情報格納の初期化
                        latestQRInfo = emptyMap()
                    } else {
                        var result = barcodeEntity.getResultCode()
                        var BarcodeName = barcodeEntity.getBarcodeName()
                        Log.d("Kotlin:MainActivity", "QR情報受信失敗 $result, $BarcodeName")
                    }
                }
            })
        }
        return true
    }

    // QRの読み取り開始
    private fun startScanQRCode(): Boolean {
        if(isInitQR){
            barcodeDecoder?.startScan()
        }

        return true
    }

    // QR結果情報を格納用MAPに変換
    private fun convertReceiveQR(barcodeEntity: BarcodeEntity) {

        // 情報として得られるものが不明確なため保留
        // uhfTagInfo.getExtraData(String) // 引数がkey情報
        // 戻り値がAPI内のクラスになるため無視
        // uhfTagInfo.getChipInfo() // 戻り値はUHFTAGInfo.ChipInfo

        // 格納前に成形が必要な情報を受ける(nullだったら空の配列にする)
        val BarcodeDataBytes: ByteArray = barcodeEntity.getBarcodeBytesData() ?: ByteArray(0)
        val PrefixBytes: ByteArray = barcodeEntity.getPrefix() ?: ByteArray(0)

        // 格納情報をmapに入れる
        latestQRInfo = mapOf(
            "type" to "QR",
            "aimID" to barcodeEntity.getAimId(),
            "barcodeBytes" to BarcodeDataBytes.toList(),
            "barcodeData" to barcodeEntity.getBarcodeData(),
            "barcodeName" to barcodeEntity.getBarcodeName(),
            "barcodeSymbology" to barcodeEntity.getBarcodeSymbology(),
            "decodeTime" to barcodeEntity.getDecodeTime(),
            "errCode" to barcodeEntity.getErrCode(),
            "prefix" to PrefixBytes.toList()
        )
    }


    // QRの読み取り終了
    private fun stopScanQRCode(): Boolean {
        if(isInitQR){
            barcodeDecoder?.stopScan()
            isInitQR = false
        }

        return true
    }


    // QRの終了処理
    private fun termQR(): Boolean {
        if(isInitQR) {
            barcodeDecoder?.close()
            isInitQR = false
        }

        return true
    }


    // 初期化
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ビープ音関係の変数初期化
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
    }

    // 破棄時にも念のためRFIDの一通りの終了処理を行う
    override fun onDestroy() {
        stopRFIDScanInternal()
        termRFID()
        termQR()
        toneGenerator.release()
        super.onDestroy()
    }
}

