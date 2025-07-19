# Void Linux Workstation Setup Scripts


> ⚠️ **Disclaimer**  
> These scripts are provided as-is, without any warranty.  
> The author declines all responsibility for any damage to data, software, or hardware resulting from their use.  
> Use them at your own risk.


This repository contains a collection of Bash scripts to automate the installation and configuration of an Void Linux development workstation.

---

## Features

- Automated installation of essential development tools and applications via `xbps-install`
- Management of dotfiles using GNU Stow with selective package application
- OpenSSL legacy renegotiation enabling for legacy software compatibility
- Centralized logging system to track script execution and errors

---

## Prerequisites

- A running Void Linux system with sudo privileges
- Internet connection
- `git` installed

---

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/fscotto/void-workstation-setup.git
   cd void-workstation-setup
   ```

2. **Run the main setup script**

   The main script will sequentially execute all setup scripts.

   ```bash
   ./install.sh
   ```

3. **Run individual scripts**

   You can also run any script individually, for example:

   ```bash
   ./scripts/dotfiles.sh
   ./scripts/openssl-legacy.sh
   ```

---

## Dotfiles

Dotfiles are managed using GNU Stow and applied selectively based on a predefined package list to avoid conflicts.

---

## Logging

All scripts use a centralized logging mechanism defined in `lib/logging.sh`. Logs are saved and useful for debugging.

---

## Contributing

Feel free to fork, submit issues, or open pull requests to improve this setup.

---

## License

This project is licensed under the MIT License.

---

## Author

Fabio Scotto di Santolo
