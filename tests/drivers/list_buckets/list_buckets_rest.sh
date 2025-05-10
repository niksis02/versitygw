#!/usr/bin/env bash

# Copyright 2024 Versity Software
# This file is licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

bucket_exists_in_list() {
  if ! check_param_count_v2 "bucket" 1 $#; then
    return 1
  fi
  for bucket in "${bucket_array[@]}"; do
    if [ "$bucket" == "$1" ]; then
      return 0
    fi
  done
  return 1
}

list_check_buckets_rest() {
  if ! check_param_count_gt "buckets" 1 $#; then
    return 1
  fi
  if ! list_buckets "rest"; then
    log 2 "error listing buckets"
    return 1
  fi
  for bucket in "$@"; do
    log 5 "bucket: $bucket"
    if ! bucket_exists_in_list "$bucket"; then
      log 2 "bucket $bucket not found"
      return 1
    fi
  done
  return 0
}

list_check_buckets_rest_with_prefix() {
  log 6 "list_check_buckets_rest_with_prefix"
  if ! check_param_count_v2 "prefix, matching, non-matching" 3 $#; then
    return 1
  fi
  if ! list_buckets_rest_prefix "$1"; then
    log 2 "error listing buckets with prefix"
    return 1
  fi
  log 5 "buckets: ${bucket_array[*]}"
  if ! bucket_exists_in_list "$2"; then
    log 2 "bucket '$2' not found"
    return 1
  fi
  if bucket_exists_in_list "$3"; then
    log 2 "bucket '$3' shouldn't have been returned"
    return 1
  fi
  return 0
}