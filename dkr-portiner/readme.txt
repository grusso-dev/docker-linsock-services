Hay que generar el key co\on:
openssl rand -base64 32 > portainer.key 
o
openssl rand -base64 32 | sudo tee portainer.key > /dev/null