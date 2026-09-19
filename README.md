# meltemsoft-web

Meltemsoft'un kurumsal tanıtım sayfası. Ayrı bir projedir — ürün
depolarıyla (`it-yonetim-programi`, `GumrukNet`) hiçbir bağı yoktur.

Sayfa tek bir HTML dosyasıdır ve internetten hiçbir şey çekmez: yazı tipi
olarak ziyaretçinin sistem fontunu kullanır, görseller SVG olarak dosyanın
içindedir. Kapalı ağda da eksiksiz açılır.

## Dosyalar

| Dosya | Ne işe yarar |
|---|---|
| `index.html` | Sayfanın kendisi. |
| `Dockerfile` | Sayfayı nginx imajının içine koyar. |
| `nginx.conf` | `/saglik` ucu, gzip, güvenlik başlıkları. |
| `k8s.yaml` | Namespace + Deployment (2 kopya) + Service + Ingress. |
| `kur-rke2.sh` | Derle → registry'ye gönder → uygula → rollout'u bekle. |

## Yerelde bakmak

Sayfa tek dosya olduğu için tarayıcıda doğrudan açılır. Sunucu davranışını
(gzip, başlıklar) görmek isterseniz:

```bash
docker build -t meltemsoft-web:1.0.0 .
docker run --rm -p 8080:80 meltemsoft-web:1.0.0
```

http://localhost:8080

## Yayına alma (RKE2)

Hedef küme: **kbmaster01**, registry `216.9.226.115:30500`,
ingressClassName `nginx`, sertifika `letsencrypt-prod` (cert-manager).
Bu değerler `k8s.yaml` içinde hazır; düzenlemeniz gereken bir şey yok.

kbmaster01'de:

```bash
git clone https://github.com/behcetakcaalan-ops/meltemsoft-web.git
cd meltemsoft-web
./kur-rke2.sh
```

Betik dört adımı sırayla yapar ve her adımda nerede durduğunu yazar.
Bitince adresleri ve ingress'in dış IP'sini söyler.

### Neden hâlâ `docker build` var

RKE2 **containerd** kullanır, Docker daemon'ı yoktur — ama bir imaj
üretmek için bir derleyiciye ihtiyaç var. kbmaster01'de Docker zaten bu iş
için kurulu; `it-yonetim-programi` da aynı şekilde derlenip aynı registry'ye
gönderiliyor. Docker burada yalnızca **derleme ve gönderme** aracı, kümenin
çalışma zamanı değil.

Derleme yapmak istemezseniz `nerdctl` ile de aynı iş görülür:

```bash
nerdctl --namespace k8s.io build -t 216.9.226.115:30500/meltemsoft-web:1.0.0 .
nerdctl --namespace k8s.io push --insecure-registry 216.9.226.115:30500/meltemsoft-web:1.0.0
```

### Düğüm ayarı gerekmiyor

Registry `216.9.226.115:30500` düğümlerin `/etc/rancher/rke2/registries.yaml`
dosyasında zaten güvenilir tanımlı. Yeni bir namespace bu ayarı etkilemez;
`registries.yaml` düğüm seviyesindedir.

## DNS

**meltemsoft.com** ve **www.meltemsoft.com** için A kayıtları ingress'in
dış IP'sine bakmalı. Bu, alan adı sağlayıcısının DNS panelinden yapılır —
kümeden yapılamaz. IP'yi öğrenmek için:

```bash
kubectl -n kube-system get svc rke2-ingress-nginx-controller
```

cert-manager HTTP-01 doğrulaması yapıyor: **sertifika ancak DNS bu IP'ye
baktıktan sonra alınabilir.** DNS'ten önce kurarsanız sayfa HTTP'de açılır,
sertifika ise DNS yayılır yayılmaz kendiliğinden gelir:

```bash
kubectl -n meltemsoft-web get certificate
```

## Güncelleme

`index.html` değiştikten sonra yeni bir sürüm etiketiyle çalıştırın:

```bash
git pull
./kur-rke2.sh 1.0.1
```

Etiketi yükseltmek önemli: aynı etiketi yeniden göndermek düğümlerde
önbellekteki eski imajın kullanılmasına yol açabilir.

## Kaldırma

```bash
kubectl delete -f k8s.yaml
```
