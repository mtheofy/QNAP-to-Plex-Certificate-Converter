#!/bin/bash
#
# This file is part of QNAP-to-Plex-Certificate-Converter.
#
# QNAP-to-Plex-Certificate-Converter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# QNAP-to-Plex-Certificate-Converter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with QNAP-to-Plex-Certificate-Converter.  If not, see <https://www.gnu.org/licenses/>.
#

# ==== CONFIGURATION ====
# Source files
STUNNEL_PEM="/mnt/HDA_ROOT/.config/stunnel/stunnel.pem"
UCA_PEM="/mnt/HDA_ROOT/.config/stunnel/uca.pem"

# Temp working directory
WORKDIR="/tmp/plex_cert_update"
mkdir -p "$WORKDIR"

# Intermediate output files
CERT="$WORKDIR/plex.crt"
KEY="$WORKDIR/plex.key"
CHAINED_CERT="$WORKDIR/plex_full.crt"
P12="$WORKDIR/plex.p12"

# Destination for Plex
PLEX_DIR="/share/CACHEDEV4_DATA/.qpkg/PlexMediaServer/Library/Plex Media Server"
PLEX_P12="$PLEX_DIR/plex.p12"

# Plex service script
PLEX_SERVICE="/etc/init.d/plex.sh"

# Optional: PKCS#12 export password (set blank if not required)
P12_PASS=""

# ==== FUNCTIONS ====

cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORKDIR"
}

exit_with_error() {
    echo "Error: $1"
    cleanup
    exit 1
}

# Cleanup on EXIT, INT (Ctrl+C), TERM
trap cleanup EXIT INT TERM

# ==== CHECKS ====

[ -f "$STUNNEL_PEM" ] || exit_with_error "$STUNNEL_PEM not found."
[ -f "$UCA_PEM" ] || exit_with_error "$UCA_PEM not found."
[ -d "$PLEX_DIR" ] || exit_with_error "Plex directory not found at $PLEX_DIR."
[ -w "$PLEX_DIR" ] || exit_with_error "Plex directory is not writable."

# Required tools
for cmd in openssl cat cmp; do
    command -v "$cmd" >/dev/null || exit_with_error "Required command '$cmd' not found."
done

# ==== PROCESSING ====

echo "Extracting private key from stunnel.pem..."
openssl pkey -in "$STUNNEL_PEM" -out "$KEY" || exit_with_error "Failed to extract private key."

echo "Extracting certificate from stunnel.pem..."
openssl x509 -in "$STUNNEL_PEM" -out "$CERT" || exit_with_error "Failed to extract certificate."

echo "Creating full certificate chain..."
cat "$CERT" "$UCA_PEM" > "$CHAINED_CERT" || exit_with_error "Failed to create full certificate chain."

echo "Creating PKCS#12 (.p12) bundle..."
openssl pkcs12 -export \
  -inkey "$KEY" \
  -in "$CERT" \
  -certfile "$UCA_PEM" \
  -out "$P12" \
  -passout pass:"$P12_PASS" || exit_with_error "Failed to create PKCS#12 bundle."

# ==== DEPLOY TO PLEX ====

echo "Copying PKCS#12 file to Plex directory..."
cp "$P12" "$PLEX_P12" || exit_with_error "Failed to copy PKCS#12 file to Plex directory."

# ==== RESTART PLEX ====

if [ -x "$PLEX_SERVICE" ]; then
  echo "Restarting Plex Media Server..."
  "$PLEX_SERVICE" restart || echo "Warning: Plex restart failed. Please restart manually."
else
  echo "Warning: Plex service script not found. Please restart Plex manually."
fi

echo "PKCS#12 certificate deployment completed successfully."
