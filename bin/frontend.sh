#!/bin/bash
echo "Installing packages..."
yarn

echo "Running compiler and watcher..."
yarn build:dev
