import tkinter as tk

import customtkinter as ctk

from core.runner import run_task

def append_to_textbox(s: str):
    txt.insert("end", s + "\n")
    txt.see("end")

app = ctk.CTk()
app.title("WinOpsToolkit GUI")
app.geometry("900x600")

frame = ctk.CTkFrame(app)
frame.pack(fill="x", padx=10, pady=10)

txt = tk.Text(app, wrap="word")
txt.pack(fill="both", expand=True, padx=10, pady=(0,10))

def on_run_clicked():
    code = run_task("workstation", ["site-plano", "workstation"], on_line=append_to_textbox)
    if code is None:
        append_to_textbox("Elevated run started (output will appear in logs).")
    else:
        append_to_textbox(f"Task finished with exit code {code}")

btn = ctk.CTkButton(frame, text="Run Standard Build", command=on_run_clicked)
btn.pack(side="left", padx=6)

app.mainloop()
