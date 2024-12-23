// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef MessageBoxC = Int32 Function(IntPtr hwnd, Pointer<Utf16> text, Pointer<Utf16> caption, Uint32 type);
typedef MessageBoxDart = int Function(int hwnd, Pointer<Utf16> text, Pointer<Utf16> caption, int type);

class WindowsPopup {
  static final user32 = DynamicLibrary.open('user32.dll');

  static final MessageBoxDart _messageBox = user32
      .lookupFunction<MessageBoxC, MessageBoxDart>('MessageBoxW');

  static const MB_OK = 0x00000000; // Juste un bouton "OK"
  static const MB_ICONWARNING = 0x00000030; // Icone d'avertissement

  static void showAutoCloseWarning(String path) {
    final text = "Attention : Vous êtes sur le point de supprimer un fichier ou dossier:\n$path".toNativeUtf16();
    final caption = "Avertissement de suppression".toNativeUtf16();

    // Créer un thread qui ferme automatiquement le message après un délai
    Timer(Duration(milliseconds: 3000), () {
      final hwnd = FindWindow(nullptr, caption); // Trouver la fenêtre du message
      if (hwnd != nullptr) {
        PostMessage(hwnd, WM_CLOSE, 0, 0); // Envoyer un message pour fermer la fenêtre
      } else {
        print('Erreur: fenêtre introuvable.');
      }
    });

    // Afficher le MessageBox avec l'icône d'avertissement
    _messageBox(0, text, caption, MB_OK | MB_ICONWARNING);

    // Libération des pointeurs alloués
    calloc.free(text);
    calloc.free(caption);
  }
}

final user32 = DynamicLibrary.open('user32.dll');

// Déclaration des fonctions nécessaires pour fermer la fenêtre
typedef FindWindowC = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef FindWindowDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef PostMessageC = Int32 Function(IntPtr hWnd, Uint32 Msg, IntPtr wParam, IntPtr lParam);
typedef PostMessageDart = int Function(int hWnd, int Msg, int wParam, int lParam);

final FindWindow = user32
    .lookupFunction<FindWindowC, FindWindowDart>('FindWindowW');
final PostMessage = user32
    .lookupFunction<PostMessageC, PostMessageDart>('PostMessageW');

// Constantes Windows pour fermer la fenêtre
const WM_CLOSE = 0x0010;
