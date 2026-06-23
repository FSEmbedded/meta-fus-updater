# Certificate / signing configuration defaults. Single source of truth, shared by the
# cert-generation task (cert-handler) and the signing consumers (base-fus-updater via
# fus-updater-defaults). Pure defaults, no tasks — safe to inherit anywhere.

# Certificate root for signing (app + RAUC). Override in machine/distro conf to use
# certs from a directory outside the layer.
CERT_BASE_DIR ??= "${LAYER_BASE_DIR}/certs"

# Build variant (prod/dev) — selects the cert set used to sign RAUC bundles + app.
FUS_BUILD_VARIANT ?= "dev"

# 1 = sign via intermediate cert; 0 = sign directly with root.
FUS_USE_INTERMEDIATE_CERT ?= "1"
