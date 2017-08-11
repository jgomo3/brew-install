#!/bin/bash

set -e

# Clean
echo "Cleaning"
rm -rf target

# Installer version
version=$(mvn -B help:evaluate -Dexpression=project.version 2>/dev/null| grep -v "^\[")
echo "Building installer version $version"

# Build uberjar and filter resources
echo "Building uberjar"
mvn -B clean package -Dmaven.test.skip=true

# Make tar file of jar and script
echo "Building installer tar file"
cp target/classes/clj.props target
cp target/classes/install-clj.sh target
cp target/classes/clj.sh target
tar -cvzf "target/install-clj-${version}.tar.gz" -Ctarget "install-clj-${version}.jar" clj.props install-clj.sh clj.sh

# Create formula file
echo "Creating formula file"
cp target/classes/clojure.rb target
sha=$(shasum -a 256 "target/install-clj-${version}.tar.gz" | cut -c 1-64)
perl -pi.bak -e "s,SHA,$sha,g" target/clojure.rb

# Deploy to s3
if [[ ! -z "$S3_BUCKET" ]]; then
  echo "Deploying https://download.clojure.org/install/brew/install-clj-${version}.tar.gz"
  aws s3 cp --only-show-errors "target/install-clj-${version}.tar.gz" "$S3_BUCKET/install/brew/install-clj-${version}.tar.gz"
  echo "Deploying https://download.clojure.org/install/brew/clojure-${version}.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/brew/clojure.rb"
  aws s3 cp --only-show-errors "target/clojure.rb" "$S3_BUCKET/install/brew/clojure-${version}.rb"
fi
