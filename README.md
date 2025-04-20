# Portsman

Collection of Alpine Packages for Robotics Applications. 

## Usage

1. Add to repositories list
```bash
echo "https://portsman.anamy.gay/aarch64" | sudo tee -a /etc/apk/repositories
```
2. Import public key
```bash
curl -o portsman-anamy.rsa.pub https://github.com/elihwyma/portsman/raw/refs/heads/main/portsman-anamy.rsa.pub && mv portsman-anamy.rsa.pub /etc/apk//etc/apk/keys/portsman-anamy.rsa.pub
```