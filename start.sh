#!/bin/sh

set -e

CHOWN=$(/usr/bin/which chown)
SQUID=$(/usr/bin/which squid)

prepare_folders() {
	echo "Preparing folders..."
	mkdir -p /etc/squid-cert/
	mkdir -p /var/cache/squid/
	mkdir -p /var/log/squid/
	"$CHOWN" -R squid:squid /etc/squid-cert/
	"$CHOWN" -R squid:squid /var/cache/squid/
	"$CHOWN" -R squid:squid /var/log/squid/
}

initialize_cache() {
	echo "Creating cache folder..."
	"$SQUID" -z

	sleep 5
}

create_cert() {
	if [ ! -f /etc/squid-cert/bump.crt ]; then
		echo "Creating certificate..."
		
		openssl dhparam -dsaparam -outform PEM -out /etc/squid-cert/bump_dhparam.pem 2048

		openssl req -new -newkey rsa:2048 -days 3650 -sha256 -nodes -x509 \
			-subj "/CN=squid-proxy-calado/O=home/C=BR" \
			-keyout /etc/squid-cert/bump.key \
			-out /etc/squid-cert/bump.crt

		openssl x509 -in /etc/squid-cert/bump.crt -outform DER -out /etc/squid-cert/bump.der


		# openssl genrsa 4096 > /etc/squid-cert/ca-private.pem

		# openssl req -new -x509 -subj "/CN=squid-proxy-calado/O=home/C=BR" -days 3650 -sha256 \
		# 	-key /etc/squid-cert/ca-private.pem \
		# 	-out /etc/squid-cert/ca-private.crt

		# openssl x509 -in /etc/squid-cert/ca-private.crt -outform DER -out /etc/squid-cert/ca-private.der


		# openssl genrsa 4096 > /etc/squid-cert/certprivatekey.pem


		# openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 \
		# 	-extensions v3_ca -keyout /etc/squid-cert/private.pem \
		# 	-out /etc/squid-cert/private.pem \
		# 	-subj "/CN=$CN/O=$O/OU=$OU/C=$C" -utf8 -nameopt multiline,utf8

		# openssl x509 -in /etc/squid-cert/private.pem \
		# 	-outform DER -out /etc/squid-cert/CA.der

		# openssl x509 -inform DER -in /etc/squid-cert/CA.der \
		# 	-out /etc/squid-cert/CA.pem

		# openssl x509 -inform PEM -in /etc/squid-cert/private.pem -out /etc/squid-cert/CA.crt
	else
		echo "Certificate found..."
	fi
}

clear_certs_db() {
	echo "Clearing generated certificate db..."
	rm -rfv /var/lib/ssl_db/
	# /usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db
	/usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db -M 20MB
	"$CHOWN" -R squid.squid /var/lib/ssl_db
}

run() {
	echo "Starting squid..."
	prepare_folders
	create_cert
	clear_certs_db
	initialize_cache
	exec "$SQUID" -NYCd 1 -f /etc/squid/squid.conf
}

run
