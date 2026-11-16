# 🚀 Quick Start - Auto-Delete Expired Products

## In 60 Secondi

### Per Utenti
1. Aggiorna l'app
2. Vai in **Impostazioni** → **"Cancella automaticamente prodotti scaduti"**
3. Attiva il toggle
4. ✅ Fatto! I prodotti scaduti verranno eliminati ogni giorno

### Per Sviluppatori

**Abilitare programmaticamente:**
```dart
await AppSettings.instance.setAutoDeleteExpiredProducts(true);
```

**Disabilitare:**
```dart
await AppSettings.instance.setAutoDeleteExpiredProducts(false);
```

**Verificare stato:**
```dart
bool isEnabled = AppSettings.instance.autoDeleteExpiredProducts;
```

**Eliminare manualmente:**
```dart
int deletedCount = await ExpiredProductsService.deleteExpiredProducts();
print('Deleted $deletedCount expired products');
```

---

## 📋 Cosa fa

✅ Scansiona i prodotti ogni 24 ore
✅ Elimina automaticamente quelli scaduti
✅ Funziona in background (anche quando l'app è chiusa)
✅ Disponibile solo su Android

---

## ⚙️ Configurazione

**File chiave:**
- `lib/service/work_manager_service.dart` - Task scheduling
- `lib/service/expired_products_service.dart` - Eliminazione prodotti
- `lib/settings_screen.dart` - UI toggle
- `lib/service/app_settings.dart` - Persistenza preferenze

**Frequenza (configurabile in `work_manager_service.dart`):**
```dart
frequency: const Duration(days: 1),  // Cambia qui per giorni/ore
```

---

## 🧪 Test

```bash
# Analisi codice
flutter analyze lib/

# Build APK
flutter build apk --debug

# Su device
flutter run -d <device_id>
```

---

## 📚 Documentazione Completa

Leggi [`AUTO_DELETE_PRODUCTS.md`](./AUTO_DELETE_PRODUCTS.md) per dettagli tecnici.

---

## ❓ FAQ

**D: Posso cambiare la frequenza?**
R: Sì, modifica `Duration(days: 1)` in `work_manager_service.dart`

**D: Come posso testare?**
R: Vedi la sezione Testing in `AUTO_DELETE_PRODUCTS.md`

**D: Funziona su iOS?**
R: No, solo Android (WorkManager è Android-specific)

**D: I prodotti vengono notificati prima dell'eliminazione?**
R: No, vengono eliminati silenziosamente (feature futura)

---

**Status**: ✅ Produzione Ready
