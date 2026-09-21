## MODIFIED Requirements

### Requirement: Chart renders all resources
The chart SHALL render all Kubernetes manifests for the full tracker stack, including the new `front-nginx` workload. The total count SHALL increase from 11 to 16: the original 11 resources plus Namespace for front (already shared), front-nginx ConfigMap, front-nginx Secret, front-nginx Deployment, front-nginx Service.

#### Scenario: Chart renders all resources
- **WHEN** `helm template tracker ./deploy/helm/tracker -f deploy/helm/tracker/values.secret.yaml` is run
- **THEN** it outputs 15 Kubernetes manifests: Namespace, 2x Secret (api + front-nginx api-credentials), 3x ConfigMap (api + nginx + front-nginx), 3x Service (api + nginx + front-nginx), 3x Deployment (api + nginx + front-nginx), StatefulSet, and PersistentVolumeClaim (via StatefulSet volumeClaimTemplate)
