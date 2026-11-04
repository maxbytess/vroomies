# vroomies v2.0.0 "yuni"

> 間違いも無駄も、全部愛していく。

Minimal, scrollable, and bloat-free Niri setup for **Arch Linux, Fedora, and Void Linux**.

---

## Quick Start

    git clone https://github.com/maxbytess/vroomies.git
    cd vroomies

### Installation

Make the installer scripts executable:

    chmod +x AETHER.sh IGNITE.sh PHANTOM.sh

Run the script for your distribution:

    ./AETHER.sh   # Arch Linux (paru / pacman)
    ./IGNITE.sh   # Fedora (dnf + COPR)
    ./PHANTOM.sh  # Void Linux (xbps + runit)

---

## Preview

![Desktop](screenshots/hero.png)

---

## Structure

    vroomies/
    ├── settings/
    │   ├── niri/
    │   ├── rofi/
    │   ├── quickshell/
    │   └── ...
    ├── AETHER.sh
    ├── IGNITE.sh
    ├── PHANTOM.sh
    └── README.md

---

## License

This project is licensed under the [MIT License](LICENSE).
