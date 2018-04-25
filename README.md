# rsautil

Rsautil is a small utility to encrypt message with rsa using
mbedtls as backend.

# motivation

The problem appeared when trying to flash a TP-Link WR1043 version 5.
Previous version of TP-Link only required either a http auth or a simple http post
and using cookies as further way to authenticate.

The WR1043 is using a frontend and backend. The frontend is completely written
in javascript and access a backend via http:// calls.

The backend is surprising a LuCI with some modified source, however the WR1043 is using
lua in the source form, which means the whole authentication can be read in source code.

The backend is generating a rsa key on boot (unsure, if every boot or only on first-boot).
So every box will have it's own private pair of key.

# how to compile?

## Using OpenWrt

Add this repository as feed to your OpenWrt installation.

```
cd source
test -e feeds.conf || cp feeds.conf.default feeds.conf
echo "src-git rsautil https://github.com/lynxis/rsautil.git" >> feeds.conf
./scripts/feeds update
./scripts/feeds install rsautil
```

Now do a `make menuconfig` and choose

```
Utilities -> Encryption -> rsautil
```

The OpenWrt build system will create a **static** linked binary which will be big.
The idea of a **static** linked binary was to use it even on small system which might not have space
for mbedtls or have the wrong version.

If you want to have a smaller binary, remove the `-static` from *rsautil/Makefile*

## Compiling manual

For compiling on a full-blown system, do

```
gcc -o rsautil rsautil.c -lmbedtls -lmbedcrypto
```

# How to flash a TP-Link WR1043v5?

Take a look into `flash_wr1043v5.sh`. The script should be run on an OpenWrt device.
