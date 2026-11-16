# 🗑️ Auto-Delete Expired Products - Implementazione Completata

## 📋 Panoramica

Implementazione della funzionalità **Auto-Delete Expired Products** per l'app Dispensiamo. Questa feature consente la rimozione automatica quotidiana dei prodotti scaduti su **Android** tramite WorkManager.

---

## ✅ Che cosa è stato implementato

### 1. **Interfaccia Utente**
- **Toggle Switch** nella pagina delle impostazioni (visibile solo su Android)
- Titolo: "Cancella automaticamente prodotti scaduti" (IT) / "Auto-delete expired products" (EN)
- Descrizione chiara con nota che la funzione è disponibile solo su Android
- Localizzazione completa in italiano e inglese

### 2. **Sistema di Persistenza**
- Salvataggio della preferenza nel database SQLite
- Chiave: `auto_delete_expired` (valori: `'true'` o `'false'`)
- Caricamento automatico all'avvio dell'app

### 3. **Job Automatico (Android)**
- **WorkManager** integrato per la programmazione di task in background
- Task programmato per eseguirsi **una volta al giorno**
- Ritardo iniziale di 1 ora (per evitare overhead all'avvio)
- Gestione sicura di errori e debug logging

### 4. **Logica di Eliminazione**
- Metodo principale: `ExpiredProductsService.deleteExpiredProducts()`
- Confronto delle date di scadenza con la data odierna
- Eliminazione automatica di prodotti `expiration_date < today`
- Ritorna il numero di prodotti eliminati

---

## 📁 File Modificati

| File | Modifiche |
|------|-----------|
| `lib/service/app_settings.dart` | Campo, getter e setter per il flag auto-delete |
| `lib/settings_screen.dart` | UI per il toggle (solo Android) |
| `lib/l10n/app_strings.dart` | Stringhe localizzate (IT/EN) |
| `lib/main.dart` | Inizializzazione WorkManager |
| `lib/model/product.dart` | Campo `expirationDate` |
| `pubspec.yaml` | Dipendenza workmanager ^0.10.0 |
| `android/app/src/main/AndroidManifest.xml` | Permesso `SCHEDULE_EXACT_ALARM` |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | Auto-generato (update) |

---

## 📁 File Creati

| File | Scopo |
|------|-------|
| `lib/service/expired_products_service.dart` | Logica di eliminazione prodotti |
| `lib/service/work_manager_service.dart` | Gestione WorkManager e task scheduling |
| `test/service/expired_products_service_test.dart` | Test unitari |
| `AUTO_DELETE_PRODUCTS.md` | Documentazione tecnica completa |

---

## 🔄 Flusso di Esecuzione

```
User enablement (Settings)
         ↓
AppSettings.setAutoDeleteExpiredProducts(true)
         ↓
DatabaseService.setSetting('auto_delete_expired', 'true')
         ↓
WorkManagerService.scheduleDeleteExpiredProductsTask()
         ↓
WorkManager registers 24-hour periodic task
         ↓
[OGNI GIORNO] callbackDispatcher() esecuzione
         ↓
ExpiredProductsService.deleteExpiredProducts()
         ↓
Eliminazione automatica prodotti scaduti ✓
```

---

## 🎯 Come Usarlo

### Utente Finale
1. Aprire **Impostazioni**
2. Scorrere fino a **"Cancella automaticamente prodotti scaduti"** (solo Android)
3. Attivare il toggle
4. Aggiungere prodotti con date di scadenza
5. **Ogni giorno** i prodotti scaduti vengono eliminati automaticamente

### Sviluppatore
```dart
// Verificare lo stato
bool isEnabled = AppSettings.instance.autoDeleteExpiredProducts;

// Abilitare
await AppSettings.instance.setAutoDeleteExpiredProducts(true);

// Disabilitare
await AppSettings.instance.setAutoDeleteExpiredProducts(false);

// Eliminare manualmente
int deletedCount = await ExpiredProductsService.deleteExpiredProducts();

// Ottenere prodotti scaduti
List expired = await ExpiredProductsService.getExpiredProducts();
```

---

## ✨ Caratteristiche Implementate

✅ **Solo Android** - Utilizza WorkManager (Android specifico)
✅ **Una volta al giorno** - Configurabile a 24 ore
✅ **Background task** - Non interferisc con l'app principale
✅ **Localizzazione** - Italiano e inglese
✅ **Error handling** - Gestione sicura degli errori
✅ **Debug logging** - Log dettagliati in debug mode
✅ **Persistenza** - Salvataggio della preferenza
✅ **Startup hook** - Scheduling automatico all'avvio

---

## 🔒 Permessi Android

Aggiunti in `AndroidManifest.xml`:
- `android.permission.SCHEDULE_EXACT_ALARM` - Per la programmazione precisa

Già disponibili:
- `android.permission.RECEIVE_BOOT_COMPLETED` - Per il riavvio del device

---

## 📊 Dipendenze

Aggiunto nel `pubspec.yaml`:
```yaml
workmanager: ^0.10.0
```

**Nota**: Versione 0.10.0 è compatibile con Flutter moderno. La versione precedente 0.5.2 aveva problemi di compatibilità Kotlin.

---

## ✔️ Verifica Qualità

```bash
✓ flutter analyze lib/ - No errors
✓ flutter build apk --debug - Build successful
✓ flutter pub get - Dependencies resolved
```

---

## 🚀 Limitazioni Attuali

| Limitazione | Motivo | Soluzione Futura |
|---|---|---|
| Solo Android | WorkManager è Android-specific | Implementare iOS WorkKit |
| Una volta al giorno | Configurazione fissa | Aggiungere UI per frequenza |
| Senza notifica | Design semplice | Aggiungere notifiche push |
| Nessun log | Semplicità | Aggiungere storico eliminazioni |

---

## 🎓 Testare la Funzionalità

### Su Emulatore/Device Android

1. **Build ed esecuzione**:
   ```bash
   flutter run -d <device_id>
   ```

2. **Abilitare la feature**:
   - Navigare in Settings
   - Attivare "Auto-delete expired products"

3. **Aggiungere prodotto scaduto**:
   - Creare un prodotto con data di scadenza = ieri
   - Verificare che sia nella pantry

4. **Verificare eliminazione**:
   - Attendere fino al prossimo ciclo WorkManager (o modificare il test)
   - Verificare che il prodotto sia stato rimosso

5. **Debug WorkManager**:
   ```bash
   # Su device/emulatore
   adb shell dumpsys jobscheduler
   ```

---

## 📚 Documentazione Aggiuntiva

Consultare i seguenti file per dettagli:

- [`AUTO_DELETE_PRODUCTS.md`](./AUTO_DELETE_PRODUCTS.md) - Guida tecnica completa
- [`lib/service/expired_products_service.dart`](./lib/service/expired_products_service.dart) - Logica di eliminazione
- [`lib/service/work_manager_service.dart`](./lib/service/work_manager_service.dart) - Gestione task

---

## 🔮 Miglioramenti Futuri

1. **Notifiche** - Avvisare l'utente quando i prodotti vengono eliminati
2. **Log** - Mantenere storico dei prodotti eliminati
3. **Frequenza configurabile** - UI per scegliere giornaliero/settimanale/mensile
4. **Preview** - Mostrare quali prodotti saranno eliminati
5. **Eccezioni** - Categoria di prodotti da escludere
6. **iOS** - Implementare su iOS con WorkKit
7. **Backup** - Opzione di backup prima dell'eliminazione

---

## 👤 Note di Implementazione

- La feature è **completamente isolata** dal resto dell'app
- Usa il **pattern Service** per separare concerns
- **WorkManager** gestisce la concorrenza e gli errori
- Aggiornamenti UI sono **reattivi** tramite `notifyListeners()`
- Tutti i metodi hanno **error handling** appropriato
- Debug logging è **condizionale** a `kDebugMode`

---

## 📞 Supporto

Per domande o bug report, consultare:
- [`AUTO_DELETE_PRODUCTS.md`](./AUTO_DELETE_PRODUCTS.md)
- Codice sorgente commentato in `lib/service/`
- Test in `test/service/expired_products_service_test.dart`

---

**Status**: ✅ Implementazione Completata e Verificata
**Data**: 2026-11-16
**Build**: ✓ Successful (APK debug generato)
**Analysis**: ✓ No issues
