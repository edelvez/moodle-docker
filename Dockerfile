FROM bitnamilegacy/moodle:5.0.2

USER root
RUN install_packages tzdata curl bash
USER 1001
