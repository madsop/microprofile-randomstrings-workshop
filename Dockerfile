# Step 0: Build the image
FROM maven:3.8.6-jdk-11 as maven
COPY pom.xml /home/app/
WORKDIR /home/app
RUN mvn -B org.apache.maven.plugins:maven-dependency-plugin:3.1.2:go-offline
COPY src /home/app/src
RUN mvn package -Dquarkus.package.type=native-sources -B

# Step 1: build the native image
FROM quay.io/quarkus/ubi-quarkus-mandrel:22.0-java11 AS native-build
COPY --chown=quarkus:quarkus --from=maven /home/app/target/native-sources /build
USER quarkus
WORKDIR /build
RUN native-image $(cat native-image.args) -J-Xmx8g

## Stage 2 : create the docker final image
FROM registry.fedoraproject.org/fedora-minimal
WORKDIR /work/
COPY --from=native-build /build/*-runner /work/application
EXPOSE 8080
ENTRYPOINT [ "/work/application" ]
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]