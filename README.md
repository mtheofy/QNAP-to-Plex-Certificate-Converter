# QNAP to Plex Certificate Converter

This script automates converting QNAP SSL certificates (`stunnel.pem` and `uca.pem`) into a PKCS#12 (`.p12`) bundle compatible with Plex Media Server. Script was tested on QTS 5.2.5 running Plex Media Server 1.41.7.

## Features
- Extracts private key and certificate from QNAP files
- Validates that the key and cert match
- Builds a full certificate chain including the CA
- Exports to PKCS#12 format with optional password
- Deploys the `.p12` file to Plex’s certificate directory
- Restarts Plex service automatically (if available)
- Includes error handling and cleanup

## Usage

1. Update paths in the script such as $PLEX_DIR.
2. Run the script on your QNAP device with administrators permissions:
   ```bash
   ./update_plex_cert.sh
3. To setup the certificate in Plex.
   - Open the Plex Web App in QNAPs
   - Go to Settings > Network
   - Under Custom certificate location, set the path to $PLEX_DIR/plex.p12 (e.g. /share/CACHEDEV4_DATA/.qpkg/PlexMediaServer/Library/Plex Media Server/plex.p12)
