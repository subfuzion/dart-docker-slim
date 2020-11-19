FROM google/dart:2.12.0-33.0.dev AS dart

FROM scratch
# Absolute minimum
COPY --from=dart /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=dart /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=dart /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=dart /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=dart /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=dart /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0

# For HTTP client requests: name service support
COPY --from=dart /etc/hosts /etc/hosts
COPY --from=dart /etc/nsswitch.conf /etc/nsswitch.conf
COPY --from=dart /etc/resolv.conf /etc/resolv.conf
COPY --from=dart /lib/x86_64-linux-gnu/libnss_dns.so.2 /lib/x86_64-linux-gnu/libnss_dns.so.2
COPY --from=dart /lib/x86_64-linux-gnu/libresolv.so.2 /lib/x86_64-linux-gnu/libresolv.so.2

# For HTTPS client requests: root certificate chain
COPY --from=0 /usr/share/ca-certificates /usr/share/ca-certificates
COPY --from=0 /etc/ssl/certs /etc/ssl/certs
