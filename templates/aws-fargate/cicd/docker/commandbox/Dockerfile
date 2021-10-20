FROM ortussolutions/commandbox:lucee5-3.4.4

# Install our box.json dependencies in an earlier layer to take advantage of caching.
COPY ./box.json ${APP_DIR}
RUN cd ${APP_DIR} && box install --production

# Copy application source files
COPY . ${APP_DIR}

# Warm-up the server
ENV HEADLESS true
RUN ${BUILD_DIR}/util/warmup-server.sh \
    && rm -f .cfconfig.json \
    || true

# Generate the finalized startup script and exit
RUN export FINALIZE_STARTUP=true \
    && $BUILD_DIR/run.sh \
    && unset FINALIZE_STARTUP \
    && rm -f server.json \
    || true
