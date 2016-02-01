FROM debian:jessie

RUN apt-get update && apt-get install -y gcc git libpcre3-dev libssl-dev make ca-certificates --no-install-recommends && \
    apt-get upgrade -y && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV LUAJIT_VERSION 2.0.4
ADD http://luajit.org/download/LuaJIT-$LUAJIT_VERSION.tar.gz /usr/local/src/
RUN cd /usr/local/src && tar xvzf LuaJIT-$LUAJIT_VERSION.tar.gz && cd LuaJIT-$LUAJIT_VERSION && \
    make && make install && cd && rm -rf /usr/local/src/*

ENV NGINX_VERSION 1.9.10
ADD http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz /usr/local/src/
RUN useradd -s /sbin/nologin -d /usr/local/nginx -M nginx && \
    mkdir -p /var/{log,run}/nginx && \
    chown nginx:nginx /var/{log,run}/nginx && \
    cd /usr/local/src && tar xvzf nginx-$NGINX_VERSION.tar.gz && \
    git clone https://github.com/openresty/lua-nginx-module.git && \
    git clone https://github.com/simpl/ngx_devel_kit.git && \
    cd /usr/local/src/nginx-$NGINX_VERSION && \
    ./configure --user=nginx --group=nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --pid-path=/var/run/nginx/nginx.pid \
                --lock-path=/var/run/nginx/nginx.lock \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --without-http_scgi_module \
                --without-http_ssi_module \
                --with-http_realip_module \
                --with-http_v2_module \
                --with-http_ssl_module \
		--with-http_stub_status_module \
                --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
                --add-module=/usr/local/src/ngx_devel_kit \
                --add-module=/usr/local/src/lua-nginx-module && \
    make -j2 && make install && \
    mkdir /etc/nginx/conf.d && \
    cd && rm -rf /usr/local/src/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
