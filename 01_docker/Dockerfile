ARG version="3.6-alpine"
FROM python
LABEL maintainer="FLD"
WORKDIR /opt
RUN apt update -y 
RUN pip install --upgrade pip \
    && git clone https://github.com/florentdubois72-del/projet-fil-rouge.git /opt/ \
    && apt clean \
    && rm -rf /var/lib/apt/list/* \
    && rm -rf jenkins-tools releases-txt README.md *pdf \
    && pip install flask --index-url=https://pypi.org/simple
COPY . /opt/
EXPOSE 8080
ENV ODOO_URL="https://www.odoo.com/"
ENV PGADMIN_URL="https://www.pgadmin.org/"
ENTRYPOINT [ "python", "app.py" ]
