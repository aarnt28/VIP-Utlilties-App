import subprocess, sys, os, tkinter as tk
import customtkinter as ctk

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

def run_task():
    ps = os.path.join(ROOT, "bootstrap", "Start-WinOps.ps1")
    cmd = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps, "-Task", "standard_build", "-Profile", "site-plano,workstation"]
    txt.insert("end", f"$ {' '.join(cmd)}\n")
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout:
            txt.insert("end", line)
            txt.see("end")
        rc = proc.wait()
        txt.insert("end", f"\nExited with code {rc}\n")
    except Exception as e:
        txt.insert("end", f"ERROR: {e}\n")

app = ctk.CTk()
app.title("WinOpsToolkit GUI")
app.geometry("900x600")

frame = ctk.CTkFrame(app)
frame.pack(fill="x", padx=10, pady=10)

btn = ctk.CTkButton(frame, text="Run Standard Build", command=run_task)
btn.pack(side="left", padx=6)

txt = tk.Text(app, wrap="word")
txt.pack(fill="both", expand=True, padx=10, pady=(0,10))

app.mainloop()
