FROM ubuntu:focal as app

# System requirements

RUN apt-get update && \
apt-get upgrade -qy && apt-get install language-pack-en locales git \
python3.8-dev python3-virtualenv libmysqlclient-dev libssl-dev build-essential wget unzip -qy && \
rm -rf /var/lib/apt/lists/*

# Python is Python3.
RUN ln -s /usr/bin/python3 /usr/bin/python

# Use UTF-8.
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


ARG COMMON_CFG_DIR="/edx/etc"
ENV CREDENTIALS_CFG_DIR="${COMMON_CFG_DIR}/credentials"

ARG COMMON_APP_DIR="/edx/app"
ARG CREDENTIALS_SERVICE_NAME="xxx"
ARG CREDENTIALS_APP_DIR="${COMMON_APP_DIR}/credentials"
ENV CREDENTIALS_APP_DIR="${COMMON_APP_DIR}/credentials"
ENV CREDENTIALS_VENV_DIR="${COMMON_APP_DIR}/credentials/venvs/credentials"
ARG SUPERVISOR_AVAILABLE_DIR="${SUPERVISOR_APP_DIR}/conf.available.d"
ARG SUPERVISOR_VENV_BIN="${SUPERVISOR_VENV_DIR}/bin"
ARG SUPERVISOR_CFG_DIR="${SUPERVISOR_APP_DIR}/conf.d"
ENV CREDENTIALS_CODE_DIR="${CREDENTIALS_APP_DIR}/credentials"
ARG CREDENTIALS_NODEENV_DIR="${COMMON_APP_DIR}/credentials/nodeenvs/credentials"
ARG CREDENTIALS_NODE_VERSION="16.14.0"
ARG CREDENTIALS_NPM_VERSION="8.5.x"
ARG SUPERVISOR_VERSION="4.2.1"

ENV PATH="$CREDENTIALS_VENV_DIR/bin:$PATH"

ENV CREDENTIALS_NODEENV_DIR "${COMMON_APP_DIR}/credentials/nodeenvs/credentials"
ENV CREDENTIALS_NODEENV_BIN "${CREDENTIALS_NODEENV_DIR}/bin"
ENV CREDENTIALS_NODE_MODULES_DIR "${CREDENTIALS_CODE_DIR}}/node_modules"
ENV CREDENTIALS_NODE_BIN "${CREDENTIALS_NODE_MODULES_DIR}/.bin"

RUN addgroup credentials
RUN adduser --disabled-login --disabled-password credentials --ingroup credentials


RUN mkdir -p "$CREDENTIALS_APP_DIR"

# Working directory will be root of repo.
WORKDIR ${CREDENTIALS_CODE_DIR}

RUN virtualenv -p python3.8 --always-copy ${CREDENTIALS_VENV_DIR}
RUN virtualenv -p python3.8 --always-copy ${SUPERVISOR_VENV_DIR}


ENV PATH "${CREDENTIALS_NODEENV_DIR}/bin:$PATH"
# No need to activate credentials venv as it is already in path
RUN pip install nodeenv

RUN nodeenv ${CREDENTIALS_NODEENV_DIR} --node=${CREDENTIALS_NODE_VERSION} --prebuilt
RUN npm install -g npm@${CREDENTIALS_NPM_VERSION}

# Copy just JS requirements and install them.
COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm install --production

# Copy just Python requirements & install them.
COPY requirements ${CREDENTIALS_CODE_DIR}/requirements
COPY Makefile ${CREDENTIALS_CODE_DIR}

#Configurations from edx_service task
RUN mkdir ${CREDENTIALS_APP_DIR}/data/
RUN mkdir ${CREDENTIALS_APP_DIR}/staticfiles/
RUN mkdir -p /edx/var/credentials/
# Log dir
RUN mkdir -p /edx/var/log/


ENV CREDENTIALS_CFG="${COMMON_CFG_DIR}/credentials.yml"
COPY configuration_files/credentials.yml ${CREDENTIALS_CFG}

# credentials service config commands below
RUN pip install -r ${CREDENTIALS_CODE_DIR}/requirements/production.txt

# After the requirements so changes to the code will not bust the image cache
COPY . ${CREDENTIALS_CODE_DIR}/

# Manage.py symlink
COPY /manage.py /edx/bin/manage.credentials

RUN chown credentials:credentials "$CREDENTIALS_APP_DIR/devstack.sh" && chmod a+x "$CREDENTIALS_APP_DIR/devstack.sh"

# placeholder file for the time being unless devstack provisioning scripts need it.
RUN touch ${CREDENTIALS_APP_DIR}/credentials_env
# Expose ports.
EXPOSE 18150


FROM app as production

ENV DJANGO_SETTINGS_MODULE credentials.settings.production

COPY scripts/credentials.sh "$CREDENTIALS_APP_DIR/credentials.sh"

ENTRYPOINT ["/edx/app/credentials/credentials.sh"]


FROM app as dev

# credentials service config commands below
RUN pip install -r ${CREDENTIALS_CODE_DIR}/requirements/dev.txt


ENV DJANGO_SETTINGS_MODULE credentials.settings.devstack

ENTRYPOINT ["/edx/app/credentials/devstack.sh"]
CMD ["start"]
