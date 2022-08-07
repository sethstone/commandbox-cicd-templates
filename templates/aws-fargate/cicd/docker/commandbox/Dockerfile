FROM ortussolutions/commandbox as workbench

# These will override configuration set in server.json
ENV BOX_SERVER_PROFILE=production
ENV BOX_SERVER_APP_CFENGINE=lucee@5.3.9.141

# Delete all existing files in App directory
RUN cd ${APP_DIR} && rm -rf ..?* .[!.]* *

# No need to set BOX_INSTALL in the environment; we explcitly `box install` dependencies here to ensure
# dev dependencies are skipped. 
COPY ./box.jso[n] ${APP_DIR}
RUN box install --production

# Warm-up the server
# Note: if using a .env file it should be copied into the host build directory prior to running `docker image build`.
COPY ./.en[v] ./.cfconfig.jso[n] ./server.jso[n] ${APP_DIR}
# Note: warmup-server.sh will start and stop the server for engine WAR expansion and startup processing
RUN ${BUILD_DIR}/util/warmup-server.sh

# Generate the finalized startup script
# Note: when FINALIZE_STARTUP is set, "run.sh" generates the startup script but doesn't run the server.
RUN FINALIZE_STARTUP=true ${BUILD_DIR}/run.sh

# Copy application source files
COPY . ${APP_DIR}
# No server.json, CFConfig, or dotenv code will be processed since we generated a finalization script.
RUN rm -f .env .cfconfig.json server.json box.json


######################################################################################################################
# Multi-stage build: Resulting image will be over 400MB smaller than a single-stage build based on 
# ortussolutions/commandbox.
######################################################################################################################
# Eclipse-Temurin provides official OpenJDK images: https://hub.docker.com/_/eclipse-temurin
FROM eclipse-temurin:11-jre-focal as app

# Copy application source files (including dependencies)
COPY --from=workbench /app /app
# But remove server.json, CFConfig, or dotenv files since we generated a finalization script.
# Note: Other unnecessary files from source should be added to .dockerignore.
RUN cd /app && rm -f .env .cfconfig.json server.json box.json

# Copy expanded WAR
COPY --from=workbench /usr/local/lib/serverHome /usr/local/lib/serverHome

# Create conventional CommandBox lib directory and copy in runwar JARs
RUN mkdir -p /usr/local/lib/CommandBox/lib
COPY --from=workbench /usr/local/lib/CommandBox/lib/runwar-*.jar /usr/local/lib/CommandBox/lib/

# Create conventional CommandBox cfml/system/config directory and copy in default urlrewite.xml file 
RUN mkdir -p /usr/local/lib/CommandBox/cfml/system/config
COPY --from=workbench /usr/local/lib/CommandBox/cfml/system/config/urlrewrite.xml /usr/local/lib/CommandBox/cfml/system/config

# Copy finalized startup script and set as the container default command (will execute runwar directly).
COPY --from=workbench /usr/local/bin/startup-final.sh /usr/local/bin/run.sh
CMD ["/usr/local/bin/run.sh"]