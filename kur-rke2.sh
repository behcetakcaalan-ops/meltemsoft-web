#!/usr/bin/env bash
# Meltemsoft tanıtım sayfası — RKE2 kümesine kurulum.
#
# kbmaster01 üzerinde, bu klasörün içinden çalıştırılır:
#   ./kur-rke2.sh           # ilk kurulum (1.0.0)
#   ./kur-rke2.sh 1.0.1     # güncelleme — yeni sürüm etiketiyle
#
# Adresler (meltemsoft.com, www.meltemsoft.com), registry ve ingress sınıfı
# k8s.yaml içinde hazır; düzenlemeniz gereken bir şey yok.
set -uo pipefail

TAG="${1:-1.0.0}"
REGISTRY=216.9.226.115:30500
IMAGE="$REGISTRY/meltemsoft-web"
NS=meltemsoft-web

# RKE2 kubectl'i PATH'te değildir, kubeconfig de standart yerde değil.
export PATH="$PATH:/var/lib/rancher/rke2/bin"
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

adim() { echo ""; echo "=== $* ==="; }

adim "1/4  İmaj derleniyor: $IMAGE:$TAG"
# RKE2 containerd kullanır; docker burada YALNIZCA imaj derleyip göndermek
# için var (bkz. DEPLOY.md Bölüm 0) — kümenin çalışma zamanı değil.
docker build -t "$IMAGE:$TAG" . || { echo "Derleme başarısız."; exit 1; }

adim "2/4  Registry'ye gönderiliyor"
docker push "$IMAGE:$TAG" || {
  echo "Gönderim başarısız."
  echo "Registry http üzerinden çalışıyor; /etc/docker/daemon.json içinde"
  echo "\"insecure-registries\": [\"$REGISTRY\"] tanımlı olmalı."
  exit 1
}

adim "3/4  Manifest uygulanıyor (sürüm: $TAG)"
sed "s|$IMAGE:1.0.0|$IMAGE:$TAG|g" k8s.yaml | kubectl apply -f - || exit 1

adim "4/4  Rollout bekleniyor"
kubectl -n "$NS" rollout status deploy/meltemsoft-web --timeout=180s || {
  echo "Rollout tamamlanmadı. Ayrıntı:"
  kubectl -n "$NS" get pods -o wide
  kubectl -n "$NS" describe deploy/meltemsoft-web | tail -30
  exit 1
}

adim "Ingress dış IP'si (DNS A kaydı buraya bakmalı)"
kubectl -n kube-system get svc rke2-ingress-nginx-controller 2>/dev/null \
  || kubectl get svc -A | grep -i ingress

echo ""
echo "=================== KURULUM TAMAM ==================="
echo "Adresler : https://meltemsoft.com  ve  https://www.meltemsoft.com"
echo "Sürüm    : $TAG"
echo "Namespace: $NS"
echo ""
echo "Sertifika cert-manager tarafından alınır; DNS yayıldıktan sonra"
echo "birkaç dakika sürer. Durumu şöyle görürsünüz:"
echo "  kubectl -n $NS get certificate"
