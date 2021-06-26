FROM jupyter/all-spark-notebook:spark-3.1.1

USER root

RUN curl https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar \
    --output $SPARK_HOME/jars/aws-java-sdk-bundle-1.11.375.jar && \
    curl https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar \
    --output $SPARK_HOME/jars/hadoop-aws-3.2.0.jar && \
    curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.20/postgresql-42.2.20.jar \
    --output $SPARK_HOME/jars/postgresql-42.2.20.jar && \
    curl https://repo1.maven.org/maven2/com/google/guava/guava/27.0-jre/guava-27.0-jre.jar \
    --output $SPARK_HOME/jars/guava-27.0-jre.jar && \
    curl https://repo1.maven.org/maven2/net/java/dev/jets3t/jets3t/0.9.4/jets3t-0.9.4.jar \
    --output $SPARK_HOME/jars/jets3t-0.9.4.jar && \
    curl https://repo1.maven.org/maven2/io/delta/delta-core_2.12/1.0.0/delta-core_2.12-1.0.0.jar \
    --output $SPARK_HOME/jars/delta-core_2.12-1.0.0.jar

WORKDIR $SPARK_HOME
COPY hive-site.xml conf/hive-site.xml

ARG HIVE_VERSION
ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}
ENV HIVE_HOME /opt/hive
ENV PATH $HIVE_HOME/bin:$PATH
WORKDIR /opt
RUN apt update && apt install -y wget procps software-properties-common && \
	wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
	tar -xzvf apache-hive-$HIVE_VERSION-bin.tar.gz && \
	mv apache-hive-$HIVE_VERSION-bin hive && \
	rm apache-hive-$HIVE_VERSION-bin.tar.gz && \
	apt autoremove --purge wget -y && \
	rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt autoremove --purge openjdk* -y && \
    apt install -y openjdk-8-jdk

RUN rm $SPARK_HOME/jars/hive-* && \
    cp $HIVE_HOME/lib/hive-* $SPARK_HOME/jars/ && \
    cp $HIVE_HOME/lib/calcite-* $SPARK_HOME/jars/ && \
    rm -rf $HIVE_HOME

RUN echo 'spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog' >> "${SPARK_HOME}/conf/spark-defaults.conf"

RUN apt install libpq-dev -y

RUN pip install delta-spark psycopg2 && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

RUN rm $SPARK_HOME/jars/guava-14.0.1.jar	

WORKDIR "${HOME}"

USER ${NB_UID}
