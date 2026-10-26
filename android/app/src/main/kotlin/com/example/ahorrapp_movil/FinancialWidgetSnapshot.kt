package com.example.ahorrapp_movil

import android.content.SharedPreferences
import org.json.JSONObject

/** Ambos tamaños leen la misma instantánea; no reutilizan las claves antiguas. */
data class FinancialWidgetSnapshot(
    val balance: String = "—",
    val ingresos: String = "—",
    val gastos: String = "—",
    val porcentaje: String = "—",
    val progreso: Int = 0,
    val fecha: String = "Abre AhorrApp"
) {
    companion object {
        fun read(data: SharedPreferences): FinancialWidgetSnapshot = try {
            val json = JSONObject(data.getString("financial_summary_v1", null) ?: "{}")
            FinancialWidgetSnapshot(
                json.optString("balance", "—"), json.optString("ingresos", "—"),
                json.optString("gastos", "—"), json.optString("porcentaje", "—"),
                json.optInt("progreso", 0).coerceIn(0, 100),
                json.optString("fecha", "Abre AhorrApp")
            )
        } catch (_: Exception) { FinancialWidgetSnapshot() }
    }
}
