resource "kubernetes_manifest" "nodepool" {
  manifest = yamldecode(file("./files/default-node-pool.yaml"))
}

resource "kubernetes_manifest" "auto-ebs-sc" {
  manifest = yamldecode(file("./files/auto-ebs-sc.yaml"))
}