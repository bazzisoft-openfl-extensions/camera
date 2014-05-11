#!/bin/bash
(cd `dirname $0` && lime rebuild . ios -clean $@)
