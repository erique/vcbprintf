#!/bin/bash
git clone https://github.com/erique/fs-uae.git
cd fs-uae
./bootstrap
./configure
make -j8
cd -

