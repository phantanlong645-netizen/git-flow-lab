FROM registry.k8s.io/kubectl:v1.36.1 AS kubectl

FROM alpine:3.22

COPY --from=kubectl /bin/kubectl /usr/local/bin/kubectl

RUN kubectl version --client
