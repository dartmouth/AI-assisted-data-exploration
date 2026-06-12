# Positron & R Installation Guide

A step-by-step guide to downloading and installing R and Positron — the free, next-generation data science IDE by Posit.

---

## Part 1: Install R

R must be installed before you can use it in Positron. Positron requires **R 4.2 or higher**.

### Step 1 — Go to the R Project Website

Visit: https://cran.r-project.org

### Step 2 — Select Your Operating System

Click the download link for your platform:

- **Windows** → click "Download R for Windows" → click "base" → click the download link (e.g. `R-4.x.x-win.exe`)
- **macOS** → click "Download R for macOS" → choose the `.pkg` file matching your chip (Apple Silicon = `arm64`, Intel = `x86_64`)
- **Linux** → click "Download R for Linux" → select your distribution (Ubuntu, Debian, Fedora, etc.) and follow the instructions shown

### Step 3 — Run the Installer

- **Windows**: Double-click the `.exe` file and follow the setup wizard. Accept all defaults unless you have specific preferences.
- **macOS**: Open the `.pkg` file and follow the installation prompts.
- **Linux**: Run the commands provided on the CRAN page for your distribution (typically `sudo apt install r-base` or equivalent).

### Step 4 — Verify the Installation

Open a terminal (or Command Prompt on Windows) and run:

```
R --version
```

You should see output showing the installed R version (e.g. `R version 4.4.x`).

---

## Part 2: Install Positron

Positron is free and available for Windows, macOS, and Linux.

### Step 1 — Check Prerequisites

Before installing, confirm the following:

| Requirement | Detail |
|---|---|
| **Windows** | Latest [Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) installed |
| **Python (optional)** | Version 3.9–3.13 if you plan to use Python |
| **R (optional)** | Version 4.2+ if you plan to use R (completed in Part 1 above) |

### Step 2 — Go to the Positron Download Page

Visit: https://positron.posit.co/download.html

### Step 3 — Accept the License Agreement

Read and accept the **Positron License Agreement** and **Posit Privacy Policy**. Acceptance is required before downloading.

### Step 4 — Download the Installer for Your Platform

Click the download button for your operating system:

- **Windows** — downloads a `.exe` installer
- **macOS (Apple Silicon / M-series)** — downloads a `.dmg` for arm64
- **macOS (Intel)** — downloads a `.dmg` for x64
- **Linux (Debian/Ubuntu)** — downloads a `.deb` package
- **Linux (Red Hat/Fedora)** — downloads a `.rpm` package

### Step 5 — Install Positron

- **Windows**: Double-click the `.exe` file. Follow the setup wizard and accept the defaults.
- **macOS**: Open the `.dmg` file, then drag the **Positron** icon into your **Applications** folder.
- **Linux (Debian/Ubuntu)**:
  ```
  sudo dpkg -i positron-*.deb
  ```
- **Linux (Red Hat/Fedora)**:
  ```
  sudo rpm -i positron-*.rpm
  ```

### Step 6 — Launch Positron

Open Positron from your Applications folder, Start Menu, or desktop shortcut.

### Step 7 — Confirm R is Detected

When Positron opens, it will automatically scan for installed interpreters.

- Look at the **bottom status bar** — it should show the detected R version.
- If R is not detected, go to: **View → Command Palette** (or `Ctrl+Shift+P` / `Cmd+Shift+P`) and type `R: Select Interpreter` to manually point Positron to your R installation.

### Step 8 — Updates

Positron automatically checks for and installs updates after the initial installation — no manual action needed.

---

## Quick Reference

| What | Where |
|---|---|
| Download R | https://cran.r-project.org |
| Download Positron | https://positron.posit.co/download.html |
| Positron install docs | https://positron.posit.co/install.html |
| Positron full documentation | https://positron.posit.co |

---

*Guide current as of June 2026.*
