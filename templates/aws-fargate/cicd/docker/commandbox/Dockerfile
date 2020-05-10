FROM ortussolutions/commandbox:lucee-light-alpine-3.0.2 as workbench

# Install our box.json dependencies in an earlier layer to take advantage of caching
COPY ./box.json ${APP_DIR}
RUN cd ${APP_DIR} && box install --production

# Copy application source files
COPY . ${APP_DIR}

# Warm-up the server
RUN ${BUILD_DIR}/util/warmup-server.sh
RUN rm -f .cfconfig.json || true

# Generate the startup script only
ENV HEADLESS true
ENV FINALIZE_STARTUP true
RUN $BUILD_DIR/run.sh
RUN rm -f server.json || true

# Debian Slim is the smallest OpenJDK image on that kernel. For most apps, this should work to run your applications
FROM adoptopenjdk/openjdk11:debianslim-jre as app

# COPY our generated files
COPY --from=workbench /app /app
# *** Observe the difference in locations between alpine and debian.
COPY --from=workbench /usr/lib/serverHome /usr/local/lib/serverHome

RUN mkdir -p /usr/local/lib/CommandBox/lib

COPY --from=workbench /usr/lib/CommandBox/lib/runwar-4.0.5.jar /usr/local/lib/CommandBox/lib/runwar-4.0.5.jar
COPY --from=workbench /usr/bin/startup-final.sh /usr/local/bin/run.sh

CMD /usr/local/bin/run.sh