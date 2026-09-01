## Certificates and signing

The framework signs RAUC bundles and the application container. Both use the same
certificate tree, laid out as *&lt;CERT_BASE_DIR&gt;/&lt;variant&gt;/&lt;purpose&gt;/*, with a shared
root under *&lt;CERT_BASE_DIR&gt;/&lt;variant&gt;/root/*.

A layer that integrates this framework does not have to implement anything for
this. It sets the definitions below and gets the guarantee that follows.

#### Enabled definitions:
- **CERT_BASE_DIR** sets the directory holding the certificate tree.
  Default value is *${LAYER_BASE_DIR}/certs*. Override it in the machine or distro
  configuration to keep certificates outside the layer; production material in
  particular should live where a layer checkout cannot reach it.
- **FUS_BUILD_VARIANT** selects the certificate set, *dev* or *prod*.
  Default value is *dev*.
- **CERT_PURPOSE** selects the signing purpose, *system* for RAUC bundles or
  *app* for the application container. It is a per-recipe input, not a global
  default.
- **FUS_USE_INTERMEDIATE_CERT** signs through an intermediate certificate when
  set to *1*, directly with the root when set to *0*. Default value is *1*.

The defaults live in *classes/fus-cert-defaults.bbclass*, a pure defaults class
without tasks. It is safe to inherit anywhere a consumer needs to read the values.

### What the framework guarantees

> On **dev** the framework may create certificates and recreate them. On **prod**
> it only ever reads.

Development trees are disposable and heal themselves: a missing keyring is
generated, and a changed configuration regenerates the tree so a developer is
never blocked by stale material.

Production material is different. The root certificate is installed into every
image as the trust anchor that verifies later updates, so replacing it strands
every device already in the field - nothing they trust can verify a bundle signed
with a new root. The framework therefore never creates or replaces production
material as a side effect of a build:

- a missing production keyring aborts the build and names the directory,
- a configuration that no longer matches the stored marker aborts as well,
  instead of regenerating,
- *scripts/generate-certs.sh* refuses `--force` together with `--env=prod`,
  whoever calls it.

Creating production certificates is a deliberate act by the integrator, into a
directory that does not yet hold any:

```shell
CERT_BASE_DIR=/path/to/certs scripts/generate-certs.sh --env=prod --purpose=system
```

### If the build refuses a production tree

The message names the stored marker and the one this build computed. The usual
cause is a production directory that was copied from a development one - the
hidden *.cert-config* marker is copied along and still says `variant=dev`.

Such a tree holds development keys. Remove it and create production material
deliberately. Do not edit the marker to make the message go away: that satisfies
the check and ships the development root as the production trust anchor, which is
the failure this refusal exists to prevent.

### Keeping keys out of version control

The layer ships a *.gitignore* for *certs/*. Development certificates are
generated on demand and are disposable; production material must never be
committed at all, because a key in the history cannot be taken back out.
