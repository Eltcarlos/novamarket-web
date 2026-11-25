# --- Binary Authorization + atestacion ---------------------------------------
# La llave de firma vive en KMS (nunca sale como archivo), coherente con que
# deployer tampoco tiene llaves propias. El pipeline (corriendo como deployer)
# firma la imagen con esta llave y crea la atestacion antes de que Cloud
# Deploy pueda desplegarla.
#
# enforcement_mode arranca en DRYRUN_AUDIT_LOG_ONLY a proposito: si se pone en
# ENFORCED de entrada, el primer deploy real se bloquea porque todavia no
# existe ningun release firmado. Cambiar a ENFORCED_BLOCK_AND_AUDIT_LOG una vez
# que el pipeline firme imagenes.

resource "google_kms_key_ring" "attestor" {
  name     = "${var.name_prefix}-attestor"
  location = "global"

  depends_on = [google_project_service.required]
}

resource "google_kms_crypto_key" "attestor" {
  name     = "${var.name_prefix}-web-attestor-key"
  key_ring = google_kms_key_ring.attestor.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "EC_SIGN_P256_SHA256"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "google_kms_crypto_key_version" "attestor" {
  crypto_key = google_kms_crypto_key.attestor.id
}

resource "google_container_analysis_note" "attestor" {
  name = "${var.name_prefix}-web-attestor-note"

  attestation_authority {
    hint {
      human_readable_name = "Build verificado de ${var.name_prefix}-web"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_binary_authorization_attestor" "web" {
  name        = "${var.name_prefix}-web-attestor"
  description = "Exige que la imagen haya sido firmada por el pipeline (deployer + KMS)."

  attestation_authority_note {
    note_reference = google_container_analysis_note.attestor.name

    public_keys {
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.attestor.public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.attestor.public_key[0].algorithm
      }
    }
  }
}

resource "google_binary_authorization_policy" "project" {
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"

    require_attestations_by = [
      "projects/${var.project_id}/attestors/${google_binary_authorization_attestor.web.name}",
    ]
  }

  depends_on = [google_project_service.required]
}

# El pipeline (deployer) necesita firmar con la llave y adjuntar la atestacion
# a la note. La ejecucion del rollout no necesita nada de esto: solo lee la
# atestacion, que ya es publica dentro del proyecto.

resource "google_kms_crypto_key_iam_member" "deployer_signer" {
  crypto_key_id = google_kms_crypto_key.attestor.id
  role          = "roles/cloudkms.signerVerifier"
  member        = google_service_account.deployer.member
}

resource "google_container_analysis_note_iam_member" "deployer_attacher" {
  note   = google_container_analysis_note.attestor.name
  role   = "roles/containeranalysis.notes.attacher"
  member = google_service_account.deployer.member
}
