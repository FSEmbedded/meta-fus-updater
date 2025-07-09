#!/usr/bin/env bash

# RAUC/App PKI Generator for multiple environments and purposes
# Supports: --env=<dev|prod> --purpose=<system|app> [--force] [--no-intermediate]

set -e    # Exit on first error
set -x    # Enable command tracing

set -euo pipefail

# Default values
ENVIRONMENT="dev"
PURPOSE="system"
FORCE=0
USE_INTERMEDIATE=1

# Validate and read args
for arg in "$@"; do
    case "$arg" in
        --env=*)
            ENVIRONMENT="${arg#*=}"
            if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
                echo "Error: --env must be 'dev' or 'prod'" >&2
                exit 1
            fi
            ;;
        --purpose=*)
            PURPOSE="${arg#*=}"
            if [[ ! "$PURPOSE" =~ ^(system|app)$ ]]; then
                echo "Error: --purpose must be 'system' or 'app'" >&2
                exit 1
            fi
            ;;
        --force) FORCE=1 ;;
        --no-intermediate) USE_INTERMEDIATE=0 ;;
        --help)
            echo "Usage: $0 [--env=dev|prod] [--purpose=system|app] [--force] [--no-intermediate]"
            exit 0
            ;;
        *) echo "Unknown argument: $arg. Use --help for usage." >&2; exit 1 ;;
    esac
done

# Paths - match BitBake expectation: certs/env/purpose/keyring.pem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${CERT_BASE_DIR:-}" ]]; then
    CERT_BASE_DIR="$SCRIPT_DIR/../certs"
fi
ENV_DIR="$CERT_BASE_DIR/$ENVIRONMENT"
ROOT_DIR="$ENV_DIR/root"
PURPOSE_DIR="$ENV_DIR/$PURPOSE"
KEYRING_FILE="$PURPOSE_DIR/keyring.pem"

# Create directory structure
mkdir -p "$ROOT_DIR" "$PURPOSE_DIR"

# Skip if already exists and not forced
if [[ -f "$KEYRING_FILE" && "$FORCE" -ne 1 ]]; then
    echo "[INFO] Keyring for '$ENVIRONMENT/$PURPOSE' already exists: $KEYRING_FILE"
    echo "       Use --force to overwrite."
    exit 0
fi

echo "[INFO] Generating PKI for '$ENVIRONMENT/$PURPOSE'"

# --- 1. Root CA (shared across purposes) ---
ROOT_KEY="$ROOT_DIR/root.key.pem"
ROOT_CERT="$ROOT_DIR/root.cert.pem"

if [[ ! -f "$ROOT_CERT" || "$FORCE" -eq 1 ]]; then
    echo "[+] Creating root certificate for environment '$ENVIRONMENT'..."
    echo "[+] which openssl $(which openssl)"
    # openssl genrsa -out "$ROOT_KEY" 4096
    openssl genrsa -out "$ROOT_KEY" 4096
    chmod 600 "$ROOT_KEY"
    openssl req -x509 -new -key "$ROOT_KEY" \
        -sha256 -days 7300 \
        -subj "/CN=Root-CA-${ENVIRONMENT}" \
        -out "$ROOT_CERT" \
        -extensions v3_ca \
        -config <(cat <<-EOF
[req]
distinguished_name = req
prompt = no

[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF
)
else
    echo "[+] Using existing root certificate for '$ENVIRONMENT'"
fi

# --- 2. Intermediate CA (optional) ---
INTER_KEY="$PURPOSE_DIR/inter.key.pem"
INTER_CERT="$PURPOSE_DIR/inter.cert.pem"

if [[ "$USE_INTERMEDIATE" -eq 1 ]]; then
    echo "[+] Creating intermediate certificate for '$PURPOSE'..."
    openssl genrsa -out "$INTER_KEY" 4096
    chmod 600 "$INTER_KEY"
    openssl req -new -key "$INTER_KEY" \
        -subj "/CN=Intermediate-CA-${ENVIRONMENT}-${PURPOSE}" \
        -out "$PURPOSE_DIR/inter.csr.pem"

    openssl x509 -req -in "$PURPOSE_DIR/inter.csr.pem" \
        -CA "$ROOT_CERT" -CAkey "$ROOT_KEY" \
        -CAserial "$PURPOSE_DIR/inter.srl" -CAcreateserial \
        -out "$INTER_CERT" \
        -days 3650 -sha256 \
        -extensions v3_ca \
        -extfile <(cat <<-EOF
[v3_ca]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF
)
    rm "$PURPOSE_DIR/inter.csr.pem"
fi

# --- 3. Signing Certificate ---
SIGN_KEY="$PURPOSE_DIR/sign.key.pem"
SIGN_CERT="$PURPOSE_DIR/sign.cert.pem"

echo "[+] Creating signing certificate for '$PURPOSE'..."
openssl genrsa -out "$SIGN_KEY" 2048
chmod 600 "$SIGN_KEY"
openssl req -new -key "$SIGN_KEY" \
    -subj "/CN=Signing-Cert-${ENVIRONMENT}-${PURPOSE}" \
    -out "$PURPOSE_DIR/sign.csr.pem"

if [[ "$USE_INTERMEDIATE" -eq 1 ]]; then
    # Sign with intermediate
    openssl x509 -req -in "$PURPOSE_DIR/sign.csr.pem" \
        -CA "$INTER_CERT" -CAkey "$INTER_KEY" \
        -CAserial "$PURPOSE_DIR/sign.srl" -CAcreateserial \
        -out "$SIGN_CERT" \
        -days 730 -sha256 \
        -extensions v3_sign \
        -extfile <(cat <<-EOF
[v3_sign]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF
)
else
    # Sign directly with root
    openssl x509 -req -in "$PURPOSE_DIR/sign.csr.pem" \
        -CA "$ROOT_CERT" -CAkey "$ROOT_KEY" \
        -CAserial "$PURPOSE_DIR/sign.srl" -CAcreateserial \
        -out "$SIGN_CERT" \
        -days 730 -sha256 \
        -extensions v3_sign \
        -extfile <(cat <<-EOF
[v3_sign]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF
)
fi
rm "$PURPOSE_DIR/sign.csr.pem"

# --- 4. Keyring (trust chain without signing cert) ---
echo "[+] Creating keyring.pem..."
cat "$ROOT_CERT" > "$KEYRING_FILE"
if [[ "$USE_INTERMEDIATE" -eq 1 ]]; then
    cat "$INTER_CERT" >> "$KEYRING_FILE"
fi
chmod 644 "$KEYRING_FILE"

# --- 5. Chain file (complete certificate chain) ---
echo "[+] Creating chain.cert.pem..."
CHAIN_FILE="$PURPOSE_DIR/chain.cert.pem"
cat "$SIGN_CERT" > "$CHAIN_FILE"
if [[ "$USE_INTERMEDIATE" -eq 1 ]]; then
    cat "$INTER_CERT" >> "$CHAIN_FILE"
fi
chmod 644 "$CHAIN_FILE"

# --- 6. Summary ---
echo "[OK] Certificates generated:"
echo "     Environment: $ENVIRONMENT"
echo "     Purpose: $PURPOSE"
echo "     Root CA: $ROOT_CERT"
if [[ "$USE_INTERMEDIATE" -eq 1 ]]; then
    echo "     Intermediate: $INTER_CERT"
fi
echo "     Signing cert: $SIGN_CERT"
echo "     Keyring: $KEYRING_FILE"
echo "     Chain: $CHAIN_FILE"
