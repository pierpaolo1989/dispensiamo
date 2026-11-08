# dispensiamo

I prodotti della dispensa vengono salvati localmente sul dispositivo: tramite SQLite su mobile e SharedPreferences nel browser per la versione web. L'app non richiede una connessione a Firebase.

La pagina **Impostazioni** permette di scegliere italiano o inglese e di configurare
con quanti giorni di anticipo ricevere un promemoria locale per le scadenze. Ogni
prodotto può avere una data di scadenza e un promemoria personalizzato che
sovrascrive il valore predefinito.

Le notifiche locali di scadenza sono disponibili nelle versioni mobile e desktop;
la versione web salva comunque le preferenze e i prodotti, ma non può inviare
notifiche locali.

L'icona Android usa il simbolo dello scontrino della splash screen. Le immagini
launcher sono generate per mdpi (48 px), hdpi (72 px), xhdpi (96 px), xxhdpi
(144 px) e xxxhdpi (192 px), con icona adattiva per Android 8 e successivi.
L'immagine master da 1024 px è in `assets/icons/dispensiamo.png`.
