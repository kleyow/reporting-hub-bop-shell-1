# First part, build the app
FROM node:16-alpine as reporting-hub-bop-shell-builder
LABEL stage=reporting-hub-bop-shell-builder

COPY package.json .
COPY yarn.lock .

RUN yarn --frozen-lockfile

COPY ./ .

# Adds the package version and commit hash
ARG REACT_APP_VERSION
ENV REACT_APP_VERSION=$REACT_APP_VERSION

ARG REACT_APP_COMMIT
ENV REACT_APP_COMMIT=$REACT_APP_COMMIT

# Public Path
ARG PUBLIC_PATH
ENV PUBLIC_PATH=$PUBLIC_PATH

RUN yarn build

# Second part, create a config at boostrap via entrypoint and and serve it
FROM caddy/caddy:alpine

# JQ is used to convert from JSON string to json file in bash
RUN apk add --no-cache jq

COPY --from=0 dist/ .
COPY docker/Caddyfile /srv/Caddyfile
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/createJSONConfig.sh /createJSONConfig.sh

RUN chmod +x /entrypoint.sh
RUN chmod +x /createJSONConfig.sh

# Provide environment variables for setting endpoints dynamically
ARG API_BASE_URL
ENV API_BASE_URL=$API_BASE_URL

ARG AUTH_ENABLED
ENV AUTH_ENABLED=$AUTH_ENABLED

ARG LOGIN_URL
ENV LOGIN_URL=$LOGIN_URL

ARG LOGOUT_URL
ENV LOGOUT_URL=$LOGOUT_URL

ARG MOCK_API
ENV MOCK_API=$MOCK_API

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

CMD ["caddy", "run", "--watch"]
# TODO: Need to add 8080 to image-scan whitelist
#       Need to switch user away from root
#       Investigate Feed data unavailable, cannot perform CVE scan for distro: alpine:3.14.2
