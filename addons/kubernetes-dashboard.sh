#!/usr/bin/env bash

HELM_COMMAND=$(k8kreator-get-tool-command "helm")
KUBECTL_COMMAND=$(k8kreator-get-tool-command "kubectl")

pre-install() {
  k8kreator-check-deps "awk"
  cat << __YAML__ | ${KUBECTL_COMMAND} apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
__YAML__
}

post-install() {
  k8kreator-msg-verbose "Getting a Bearer Token for ServiceAccount"
  k8kreator-msg-info "IMPORTANT: Bearer Token that can be used to log in to Dashboard"
  ${KUBECTL_COMMAND} -n kubernetes-dashboard create token admin-user
}

k8kreator-addons-install-kubernetes-dashboard() {
  k8kreator-addons-update-kubernetes-dashboard $@
}

k8kreator-addons-update-kubernetes-dashboard() {
  local addon_version=$1
  pre-install
  ${HELM_COMMAND} upgrade kubernetes-dashboard kubernetes-dashboard \
    --repo https://kubernetes.github.io/dashboard/ \
    --version ${addon_version} \
    --create-namespace --namespace kubernetes-dashboard \
    --install --atomic --cleanup-on-fail \
    --values ${K8KREATOR_ADDONSDIR}/kubernetes-dashboard/values.yaml \
    --set "app.ingress.hosts[0]=dashboard.${K8KREATOR_TARGET}"
  [ $? -eq 0 ] && post-install
}

k8kreator-addons-uninstall-kubernetes-dashboard() {
  local addon_version=$1
  ${HELM_COMMAND} uninstall kubernetes-dashboard \
    --namespace kubernetes-dashboard
}

# End of file
