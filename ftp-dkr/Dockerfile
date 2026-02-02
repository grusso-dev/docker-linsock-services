FROM fauria/vsftpd

# Copiamos un entrypoint personalizado
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Usamos nuestro entrypoint y después lanzamos vsftpd
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/run-vsftpd.sh"]
