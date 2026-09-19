#!/usr/bin/env bash
# Takılan bir kurulumun nedenini tek seferde toplar.
# Çalıştır:  ./tani.sh    — çıktının tamamını paylaş.
export PATH="$PATH:/var/lib/rancher/rke2/bin"
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
NS=meltemsoft-web

echo "===== POD'LAR ====="
kubectl -n $NS get pods -o wide

echo ""
echo "===== HAZIR OLMAYAN POD'UN AYRINTISI ====="
POD=$(kubectl -n $NS get pods --no-headers 2>/dev/null \
      | awk '$2 !~ /^([0-9]+)\/\1$/ || $3 != "Running" {print $1; exit}')
if [ -n "$POD" ]; then
  echo "Pod: $POD"
  kubectl -n $NS describe pod "$POD" | sed -n '/Containers:/,$p' | head -60
  echo ""
  echo "--- kapsayıcı günlüğü ---"
  kubectl -n $NS logs "$POD" --tail=40 2>&1
else
  echo "Hazır olmayan pod yok."
fi

echo ""
echo "===== OLAYLAR (son 20) ====="
kubectl -n $NS get events --sort-by=.lastTimestamp 2>/dev/null | tail -20

echo ""
echo "===== REPLICASET DURUMU ====="
kubectl -n $NS get rs

echo ""
echo "===== REGISTRY'DE HANGİ ETİKETLER VAR ====="
curl -s --max-time 10 http://216.9.226.115:30500/v2/meltemsoft-web/tags/list || echo "registry'ye ulaşılamadı"
echo ""

echo "===== DÜĞÜM KAYNAKLARI ====="
kubectl get nodes
