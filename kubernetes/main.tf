# ============================================================
# Aplicação — aplica todos os manifestos YAML do diretório k8s/
# ============================================================
# O diretório k8s/ é a fonte única de verdade. O Terraform aplica
# esses manifestos (kubectl_manifest) e o ArgoCD os sincroniza do
# Git — os dois convergem para o mesmo estado desejado.
data "kubectl_path_documents" "app" {
  pattern = "${path.module}/../k8s/*.yaml"
}

resource "kubectl_manifest" "app" {
  for_each  = toset(data.kubectl_path_documents.app.documents)
  yaml_body = each.value
}
