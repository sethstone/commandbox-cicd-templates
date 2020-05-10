FROM ortussolutions/commandbox
# Warm up the server with a specific version of CF Engine version. To see which
# versions are available on Forgebox run:
#   box forgebox search "Lucee CF Engine"
ENV CFENGINE=lucee@5.3.4+80
ENV HEADLESS="true"

# Install our box.json dependencies in an earlier layer to take advantage of caching
COPY ./box.json ${APP_DIR}
RUN cd ${APP_DIR} && box install --production

# Copy application source files
COPY . ${APP_DIR}

# Warm-up the server
RUN ${BUILD_DIR}/util/warmup-server.sh
RUN rm -f .cfconfig.json || true

# Generate the finalized startup script and exit
RUN export FINALIZE_STARTUP=true;$BUILD_DIR/run.sh;unset FINALIZE_STARTUP
RUN rm -f server.json || true