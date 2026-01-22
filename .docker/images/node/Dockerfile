############################## BASE NODE STAGE ########################################
ARG NODE_VERSION=latest
FROM node:${NODE_VERSION} AS base
EXPOSE 3000
EXPOSE 80
WORKDIR /app

############################## SVELTE ########################################
ARG NODE_VERSION=latest
FROM base AS svelte
EXPOSE 4173
EXPOSE 5173
############################## END ########################################
