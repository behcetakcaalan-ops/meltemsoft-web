# Meltemsoft tanıtım sayfası — tek dosyalık statik site.
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

# nginx imajı 80'i dinler; küme tarafında Service 80'e bağlanır.
EXPOSE 80
