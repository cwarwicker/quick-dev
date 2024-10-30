############################## BASE PYTHON STAGE ########################################
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION} AS base
EXPOSE 9090
WORKDIR /app
CMD ["python", "-m" , "http.server", "9090"]

############################## DJANGO ########################################
ARG PYTHON_VERSION=3.13
FROM base AS django
CMD ["sleep", "infinity"]
############################## END ########################################
