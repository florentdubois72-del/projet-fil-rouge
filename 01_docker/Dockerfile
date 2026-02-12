#Bonjour
FROM python:3.6-alpine
LABEL maintainer="FLD"
WORKDIR /opt
RUN pip install --upgrade pip
RUN pip install flask --index-url=https://pypi.org/simple
COPY . /opt/
EXPOSE 8080
ENV ODOO_URL="https://www.odoo.com/"
ENV PGADMIN_URL="https://www.pgadmin.org/"
ENTRYPOINT [ "python", "app.py" ]
