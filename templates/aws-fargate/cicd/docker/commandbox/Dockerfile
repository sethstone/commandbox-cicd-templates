FROM ortussolutions/commandbox:lucee5-3.0.2

# Install our box.json dependencies in an earlier layer to take advantage of caching.
# We have to install testbox into the image in order to run tests once the container image is built.  It's not ideal
# to deploy testbox, but the trade-off for being able to easily test the container iamage using standard tools seems
# worth it.
COPY ./box.json ${APP_DIR}
RUN cd ${APP_DIR} && box install --production && box install testbox

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