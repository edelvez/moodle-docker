FROM bitnami/moodle:5.1.2

USER root
RUN install_packages tzdata curl bash
USER 1001
