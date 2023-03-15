#
# Copyright (C) 2023 Famoco
#

# Sign a package using the specified key/cert.
define sign-package
$(hide) $(DOCKER_CMD) apksigner sign \
  $(if $(SIGNER_ARGS),$(SIGNER_ARGS)) \
  --key $(KEYSET).pk8 --cert $(KEYSET).x509.pem \
  --out $2 $1
endef

KEYSET := keystore/testkey
