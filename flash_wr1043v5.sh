#!/bin/sh
# MIT Alexander Couzens 2018
#
# written for OpenWrt
#
# flash a 1043v5
#
# The flash procedure will do:
# 1. retrieve a rsa public key
# 2. encrypt password with rsa
# 3. login via username/password
# 4. upload the firmware
# 5. trigger upgrade

. /usr/share/libubox/jshn.sh

_log() {
        local level=$1
        shift
        logger -s -t flasher -p "daemon.$level" "$@"
}

load_json_check() {
	# load the json and check for success
	local file=$1

	json_init
	json_load "$(cat "$file")"
	json_get_var status success
	[ "$status" == "1" ]
}

flash_1043v5() {
	# clean up state
	rm -f /tmp/cookie_jar

	# 1. retrieve a rsa public key
	# rsa public key (n, e params)
	curl 'http://192.168.0.1/cgi-bin/luci/;stok=/login?form=login' \
		-H 'Host: 192.168.0.1' \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
		-H 'X-Requested-With: XMLHttpRequest' \
		-H 'Connection: keep-alive' \
		--data 'operation=read' \
		-o /tmp/key

	if [ $? -ne 0 ] ; then
		_log error "Can not download the keys"
		return
	fi

	if ! load_json_check /tmp/key ; then
		_log error "Can not get the keys. $(cat /tmp/key)"
		return
	fi

	json_select data
	password=""
	json_get_values password password

	# 2. encrypt password with rsa
	rsaN="$(echo "$password" | awk '{print $1}')"
	rsaE="$(echo "$password" | awk '{print $2}')"
	HASH=$(/flasher/rsautil -m admin -e "$rsaE" -n "$rsaN")
	if [ $? -ne 0 ] ; then
		_log error "rsautil could not encrypt the message."
		return
	fi

	# 3. login via username/password
	# login into the api. We will get a stok and a cookie (sysauth)
	curl 'http://192.168.0.1/cgi-bin/luci/;stok=/login?form=login' \
		-H 'Host: 192.168.0.1' \
		-H 'Accept: application/json, text/javascript, */*; q=0.01' \
		-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
		-H 'X-Requested-With: XMLHttpRequest' \
		-H 'Connection: keep-alive' \
		--data "operation=login&username=admin&password=$HASH" \
		--cookie-jar "/tmp/cookie_jar" \
		-o /tmp/login

	# login should look like
	# {"success":true,"data":{"stok":"3bd1681f2d2993726f6a2633b35c5ed1"}
	if ! load_json_check /tmp/login ; then
		_log error "Can not upload the firmware. $(cat /tmp/login)"
		return
	fi

	json_select data
	stok=""
	json_get_var stok stok

	# 4. upload the firmware
	# this will only upload and check the firmware image, but not doing the upgrade.
	curl \
		-H 'Host: 192.168.0.1' \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		-H 'Referer: http://192.168.0.1/webpages/index.html '\
		-H 'DNT: 1' \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
		\
		--cookie-jar "/tmp/cookie_jar" \
		--cookie "/tmp/cookie_jar" \
		\
		-F 'keep=on' \
		-F 'image=@/flasher/image' \
		-F 'operation=firmware' \
		\
		"http://192.168.0.1/cgi-bin/luci/;stok=$stok/admin/firmware?form=upgrade" \
		-o /tmp/status_firmware

	if ! load_json_check /tmp/status_firmware ; then
		_log error "Can not upload the firmware. $(cat /tmp/status_firmware)"
		return
	fi

	# 5. trigger upgrade
	curl \
		-H 'Host: 192.168.0.1' \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		-H 'Referer: http://192.168.0.1/webpages/index.html '\
		-H 'DNT: 1' \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
		\
		--cookie-jar "/tmp/cookie_jar" \
		--cookie "/tmp/cookie_jar" \
		\
		-F 'operation=checklast' \
		\
		"http://192.168.0.1/cgi-bin/luci/;stok=$stok/admin/firmware?form=upgrade" \
		-o /tmp/checklast
}


