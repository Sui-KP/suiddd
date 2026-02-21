package sui.k.ddd

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.ServerSocket
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newCachedThreadPool()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startNativeServer()
    }

    private fun startNativeServer() {
        executor.execute {
            try {
                val server = ServerSocket(9999)
                while (true) {
                    val socket = server.accept()
                    executor.execute {
                        try {
                            val reader = BufferedReader(InputStreamReader(socket.inputStream))
                            val out = socket.getOutputStream()
                            val line = reader.readLine() ?: ""
                            val parts = line.split("|")
                            if (parts.isNotEmpty()) {
                                val cmd = parts[0]
                                val arg = if (parts.size > 1) parts[1] else null
                                when (cmd) {
                                    "suiddd-export_app_info" -> streamAppInfo(arg, out)
                                    "suiddd-export_apk" -> streamApk(arg, out)
                                    "suiddd-export_app_activity" -> streamActivities(arg, out)
                                }
                            }
                            out.flush()
                        } catch (_: Exception) {
                        } finally {
                            socket.close()
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    private fun streamAppInfo(targetPkg: String?, out: OutputStream) {
        val pm = packageManager
        val flags = if (Build.VERSION.SDK_INT >= 30) 0x02000000 else 128
        val apps = pm.getInstalledApplications(flags)
        val filtered =
            if (!targetPkg.isNullOrEmpty()) apps.filter { it.packageName == targetPkg } else apps
        for (app in filtered) {
            try {
                val pi = pm.getPackageInfo(app.packageName, 0)
                val appName = pm.getApplicationLabel(app).toString()
                val pkg = app.packageName
                val ver = pi.versionName ?: "N/A"
                val apk = app.sourceDir
                val size = String.format("%.2f MB", File(apk).length() / (1024.0 * 1024.0))
                val sdk = "${app.minSdkVersion}-${app.targetSdkVersion}"
                val uid = app.uid.toString()
                val sys = if ((app.flags and 1) != 0) "1" else "0"
                val data = app.dataDir ?: "N/A"
                val first =
                    java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                        .format(java.util.Date(pi.firstInstallTime))
                val last =
                    java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                        .format(java.util.Date(pi.lastUpdateTime))
                val info =
                    "$appName\n$ver\n$pkg\n$size\n$sdk\n$uid\n$sys\n$apk\n$data\n$first\n$last\n\n"
                out.write(info.toByteArray())
            } catch (_: Exception) {
            }
        }
        out.write("DONE\n".toByteArray())
    }

    private fun streamApk(targetPkg: String?, out: OutputStream) {
        if (targetPkg.isNullOrEmpty()) return
        try {
            val app = packageManager.getApplicationInfo(targetPkg, 0)
            File(app.sourceDir).inputStream().use { it.copyTo(out) }
        } catch (_: Exception) {
        }
    }

    private fun streamActivities(targetPkg: String?, out: OutputStream) {
        val pm = packageManager
        val flags = if (Build.VERSION.SDK_INT >= 30) 0x02000000 else 128
        val apps = pm.getInstalledApplications(flags)
        val filtered =
            if (!targetPkg.isNullOrEmpty()) apps.filter { it.packageName == targetPkg } else apps
        for (app in filtered) {
            try {
                val pi = pm.getPackageInfo(app.packageName, 1)
                val activities = pi.activities ?: continue
                out.write("Package: ${app.packageName}\n".toByteArray())
                for (act in activities) {
                    out.write("${act.name} (Exported: ${act.exported})\n".toByteArray())
                }
                out.write("\n".toByteArray())
            } catch (_: Exception) {
            }
        }
        out.write("DONE\n".toByteArray())
    }
}