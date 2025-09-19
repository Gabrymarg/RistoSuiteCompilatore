import subprocess
import time
import pyautogui
import tkinter as tk
from threading import Thread
import win32gui
import win32con

EDGE_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
URL = "http://172.50.0.50:5001/"

def launch_edge():
    # Avvia Edge minimizzato
    proc = subprocess.Popen(
        [EDGE_PATH, "--kiosk", URL, "--edge-kiosk-type=fullscreen", "--inprivate"],
        shell=False,
        creationflags=subprocess.CREATE_NEW_CONSOLE | subprocess.CREATE_NO_WINDOW
    )
    time.sleep(3)  # attesa apertura

    # Forza la finestra della splash in primo piano
    hwnd = win32gui.FindWindow(None, "RistoSuite")
    if hwnd:
        win32gui.ShowWindow(hwnd, win32con.SW_SHOW)
        win32gui.SetForegroundWindow(hwnd)

    # Invia TAB TAB ENTER
    pyautogui.press('tab')
    pyautogui.press('tab')
    pyautogui.press('enter')

    # Chiudi splash screen
    root.destroy()

# Splash screen
root = tk.Tk()
root.title("RistoSuite")
root.geometry("400x200+500+300")
root.overrideredirect(True)
root.attributes("-topmost", True)
label = tk.Label(root, text="Caricamento RistoSuite...", font=("Arial", 16))
label.pack(expand=True)

# Avvia Edge in thread separato
Thread(target=launch_edge).start()
root.mainloop()
