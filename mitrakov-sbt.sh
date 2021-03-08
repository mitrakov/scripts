#!/bin/bash

clear
set -e    # ignore the rest of the script in case of errors

echo "This script will create a simple Scala Project"
echo "by: @mitrakov (https://github.com/mitrakov)"
echo
echo -n "Project name:"
read </dev/tty
NAME=$REPLY

## build.sbt file ##
cat <<EOF >build.sbt
name := "$NAME"
organization := "com.mitrakov.sandbox"
version := "1.0.0"
scalaVersion := "2.13.4"

libraryDependencies ++= Seq(
  "com.typesafe" % "config" % "1.4.0",
  "com.typesafe.scala-logging" %% "scala-logging" % "3.9.2",
  "ch.qos.logback" % "logback-classic" % "1.1.3" % Runtime,
  "org.scalatest" %% "scalatest" % "3.2.0" % Test,
)
EOF

## project structure ##
mkdir -p src/main/scala/com/mitrakov/sandbox/$NAME
mkdir -p src/test/scala/com/mitrakov/sandbox/$NAME
mkdir -p src/main/resources

cat <<EOF >src/main/scala/com/mitrakov/sandbox/$NAME/Main.scala
package com.mitrakov.sandbox.$NAME

object Main extends App {
  println("Hello world")
}
EOF

## logback.xml ##
cat <<EOF >src/main/resources/logback.xml
<configuration>
  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="INFO">
    <appender-ref ref="STDOUT" />
  </root>
</configuration>
EOF

## building ##
sbt compile
sbt run
