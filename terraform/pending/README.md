# Diseño objetivo, no aplicado

Terraform ignora esta carpeta. Requiere permisos que la cuenta del proyecto asignado no tiene:

| Archivo | Roles necesarios |
|---|---|
| `binauthz.tf` | `cloudkms.admin`, `containeranalysis.admin`, `binaryauthorization.attestorsAdmin`, `binaryauthorization.policyEditor` |
| `deploy.tf` | `clouddeploy.admin` |
| `iam.tf` | `resourcemanager.projectIamAdmin` |

Copias completas: al reactivarlas hay que fusionarlas con los `.tf` de la carpeta superior.
