#Bonjour
FROM python:trixie
LABEL maintainer="FLD"
WORKDIR /opt
RUN apt-get update \
    && apt-get install --no-install-recommends -y git \
    && git clone https://github.com/florentdubois72-del/projet-fil-rouge.git /opt/ \
    && apt-get clean \
    && rm -rf /var/lib/apt/list/* \
    && rm -rf jenkins-tools releases-txt README.md *pdf \
    && pip3 install flask
RUN pip install --upgrade pip
RUN pip install flask --index-url=https://pypi.org/simple
COPY . /opt/
EXPOSE 8080
ENV ODOO_URL="https://www.odoo.com/"
ENV PGADMIN_URL="https://www.pgadmin.org/"
ENTRYPOINT [ "python", "app.py" ]
