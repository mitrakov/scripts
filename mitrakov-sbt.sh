#!/bin/bash

clear
set -e    # ignore the rest of the script in case of errors

# checking environment
if ! [ `which java` ]; then
  echo "You have no java installed. Please install jdk first"
  exit -1
fi
if ! [ `which sbt` ]; then
  echo "You have no sbt installed. Please install sbt first"
  exit -1
fi

echo "This script will create a simple Scala Project"
echo "by: @mitrakov (https://github.com/mitrakov)"
echo
echo -ne "\033[32mProject name:\033[0m"
read </dev/tty
NAME=$REPLY
echo -ne "\033[32mFull package name:\033[0m"
read </dev/tty
PACKAGE=$REPLY
DIRPATH=$(echo $PACKAGE | sed "s/\./\//g")

## build.sbt file ##
cat <<EOF >build.sbt
name := "$NAME"
organization := "$PACKAGE"
version := "1.0.0"
scalaVersion := "2.13.7"

libraryDependencies ++= Seq(
  "com.typesafe" % "config" % "1.4.1",
  "com.typesafe.scala-logging" %% "scala-logging" % "3.9.4",
  "ch.qos.logback" % "logback-classic" % "1.2.5" % Runtime,
  "org.scalatest" %% "scalatest" % "3.2.9" % Test,
)
EOF

## project structure ##
mkdir -p src/main/scala/$DIRPATH/$NAME
mkdir -p src/test/scala/$DIRPATH/$NAME
mkdir -p src/main/resources

cat <<EOF >src/main/scala/$DIRPATH/$NAME/Main.scala
package $PACKAGE.$NAME

object Main extends App {
  println("\n\nHello world\n\n")
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

## application.conf ##
echo "" > src/main/resources/application.conf

## building ##
sbt compile run
