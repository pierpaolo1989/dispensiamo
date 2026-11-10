import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get _isItalian => languageCode == 'it';

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);

  String get appName => 'Dispensiamo';
  String get splashTagline => _isItalian
      ? 'La tua dispensa, sempre sotto controllo.'
      : 'Your pantry, always under control.';
  String get home => _isItalian ? 'Home' : 'Home';
  String get pantry => _isItalian ? 'Dispensa' : 'Pantry';
  String get settings => _isItalian ? 'Impostazioni' : 'Settings';
  String get language => _isItalian ? 'Lingua' : 'Language';
  String get italian => 'Italiano';
  String get english => 'English';
  String get homeHeadline => _isItalian
      ? 'La tua spesa,\nsempre sotto controllo.'
      : 'Your groceries,\nalways under control.';
  String get homeDescription => _isItalian
      ? 'Scansiona uno scontrino o aggiungi i prodotti alla tua dispensa.'
      : 'Scan a receipt or add products to your pantry.';
  String get takePhoto => _isItalian ? 'Scatta una foto' : 'Take a photo';
  String get chooseFromGallery =>
      _isItalian ? 'Seleziona dalla galleria' : 'Choose from gallery';
  String get camera => _isItalian ? 'Fotocamera' : 'Camera';
  String get cameraUnavailable => _isItalian
      ? 'Impossibile avviare la fotocamera'
      : 'Unable to start the camera';
  String cameraError(Object error) => _isItalian
      ? 'Scatto non riuscito: $error'
      : 'Could not take the photo: $error';
  String galleryError(Object error) => _isItalian
      ? 'Impossibile selezionare la foto: $error'
      : 'Could not select the photo: $error';
  String get result => _isItalian ? 'Risultato' : 'Result';
  String get reviewReceipt =>
      _isItalian ? 'Rivedi lo scontrino' : 'Review receipt';
  String get receiptReviewDescription => _isItalian
      ? 'Controlla i prodotti e i prezzi riconosciuti prima di aggiungerli alla dispensa.'
      : 'Check the recognized products and prices before adding them to your pantry.';
  String get receiptText =>
      _isItalian ? 'Testo letto dallo scontrino' : 'Text read from receipt';
  String get addReceiptProduct => _isItalian ? 'Aggiungi riga' : 'Add item';
  String get removeReceiptProduct =>
      _isItalian ? 'Rimuovi prodotto' : 'Remove product';
  String get noReceiptProducts => _isItalian
      ? 'Non sono stati riconosciuti prodotti. Puoi aggiungere le righe manualmente.'
      : 'No products were recognized. You can add items manually.';
  String get importReceiptProducts =>
      _isItalian ? 'Aggiungi alla dispensa' : 'Add to pantry';
  String receiptAnalysisError(Object error) => _isItalian
      ? 'Impossibile leggere lo scontrino: $error'
      : 'Could not read the receipt: $error';
  String get importReceiptError => _isItalian
      ? 'Impossibile salvare i prodotti. Riprova.'
      : 'Could not save the products. Please try again.';
  String productsImported(int count) => _isItalian
      ? count == 1
          ? 'Aggiunto 1 prodotto alla dispensa'
          : 'Aggiunti $count prodotti alla dispensa'
      : count == 1
          ? 'Added 1 product to the pantry'
          : 'Added $count products to the pantry';
  String get invalidReceiptPrice =>
      _isItalian ? 'Inserisci un prezzo valido' : 'Enter a valid price';
  String recognizedText(String text) =>
      _isItalian ? 'Testo riconosciuto:\n\n$text' : 'Recognized text:\n\n$text';
  String get analysisError => _isItalian
      ? "Errore durante l'analisi"
      : 'An error occurred while analyzing the receipt';
  String get addProduct => _isItalian ? 'Aggiungi prodotto' : 'Add product';
  String get editProduct => _isItalian ? 'Modifica prodotto' : 'Edit product';
  String get name => _isItalian ? 'Nome' : 'Name';
  String get price => _isItalian ? 'Prezzo' : 'Price';
  String get enterName => _isItalian ? 'Inserisci un nome' : 'Enter a name';
  String get enterValidPrice =>
      _isItalian ? 'Inserisci un prezzo valido' : 'Enter a valid price';
  String get cancel => _isItalian ? 'Annulla' : 'Cancel';
  String get save => _isItalian ? 'Salva' : 'Save';
  String get retry => _isItalian ? 'Riprova' : 'Try again';
  String get loadMore => _isItalian ? 'Carica altri' : 'Load more';
  String get noProducts =>
      _isItalian ? 'Nessun prodotto salvato' : 'No saved products';
  String get addProductTooltip =>
      _isItalian ? 'Aggiungi prodotto' : 'Add product';
  String get deleteProduct => _isItalian ? 'Elimina' : 'Delete';
  String deleteProductError(Object error) => _isItalian
      ? 'Impossibile eliminare il prodotto: $error'
      : 'Could not delete the product: $error';
  String deleteProductReminderError(Object error) => _isItalian
      ? 'Prodotto eliminato, ma impossibile rimuovere il promemoria: $error'
      : 'Product deleted, but could not cancel its reminder: $error';
  String loadProductsError(Object error) => _isItalian
      ? 'Impossibile caricare i prodotti: $error'
      : 'Could not load products: $error';
  String saveProductError(Object error) => _isItalian
      ? 'Impossibile salvare il prodotto: $error'
      : 'Could not save the product: $error';
  String saveProductReminderError(Object error) => _isItalian
      ? 'Prodotto salvato, ma promemoria non programmato: $error'
      : 'Product saved, but reminder could not be scheduled: $error';
  String get notificationsDenied => _isItalian
      ? 'Permesso notifiche negato: attivalo nelle impostazioni del dispositivo.'
      : 'Notification permission denied. Enable it in your device settings.';
  String get notificationsUnavailable => _isItalian
      ? 'I promemoria con notifiche non sono disponibili nella versione web.'
      : 'Notification reminders are not available in the web version.';
  String get expirationDate =>
      _isItalian ? 'Data di scadenza' : 'Expiration date';
  String get chooseExpirationDate =>
      _isItalian ? 'Scegli una data' : 'Choose a date';
  String get clearExpirationDate => _isItalian ? 'Rimuovi data' : 'Clear date';
  String get reminder => _isItalian ? 'Promemoria' : 'Reminder';
  String get defaultReminder =>
      _isItalian ? 'Usa il valore predefinito' : 'Use default';
  String get noReminder => _isItalian ? 'Nessun promemoria' : 'No reminder';
  String get defaultAlert =>
      _isItalian ? 'Avviso predefinito' : 'Default reminder';
  String get expirationDateRequiredForReminder => _isItalian
      ? 'Aggiungi una data di scadenza per attivare il promemoria.'
      : 'Add an expiration date to enable a reminder.';
  String expirationLabel(String date) =>
      _isItalian ? 'Scadenza: $date' : 'Expires: $date';

  String get settingsDescription => _isItalian
      ? 'Personalizza lingua e avvisi per i prodotti in scadenza.'
      : 'Choose your language and reminders for expiring products.';
  String get expirationReminders =>
      _isItalian ? 'Avvisi di scadenza' : 'Expiration reminders';
  String defaultAlertDays(int days) {
    if (days == 1) {
      return _isItalian ? 'Avvisa 1 giorno prima' : 'Notify 1 day before';
    }
    return _isItalian
        ? 'Avvisa $days giorni prima'
        : 'Notify $days days before';
  }

  String get reminderOverrideHint => _isItalian
      ? 'Vale per i prodotti che usano il predefinito; puoi impostare un avviso diverso per ogni prodotto.'
      : 'This applies to products using the default; you can set a different reminder for each product.';
  String get reminderPermissionExplanation => _isItalian
      ? 'Il permesso per le notifiche viene richiesto quando attivi un promemoria.'
      : 'Notification permission is requested when you enable a reminder.';
  String settingsSaveError(Object error) => _isItalian
      ? 'Impossibile aggiornare le impostazioni: $error'
      : 'Could not update settings: $error';
}
