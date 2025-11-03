#!/bin/bash
set -e

echo "Packaging Lambda function..."
cd lambda
zip -r image_analyzer.zip image_analyzer.py
echo "Lambda package created: image_analyzer.zip"