package tech.soit.quiet.utils

import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


suspend fun MethodChannel.invokeAsync(method: String, arguments: Any?): Any? =
    withContext(Dispatchers.Main) {
        suspendCoroutine { continuation ->
            invokeMethod(method, arguments, object : MethodChannel.Result {

                override fun notImplemented() {
                    continuation.resumeWithException(NotImplementedError("$method , $arguments"))
                }


                override fun success(result: Any?) {
                    continuation.resume(result)
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    continuation.resumeWithException(Exception("$errorCode , $errorMessage , $errorDetails"))
                }
            })
        }

    }
